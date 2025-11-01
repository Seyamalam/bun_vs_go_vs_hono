import { serve } from "bun";
import { Pool } from "pg";

// Database connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || "postgresql://benchmarkuser:benchmarkpass@localhost:5432/benchmarkdb",
  max: 20,
});

// Helper function to send JSON response
function jsonResponse(data: any, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// Helper function to send error response
function errorResponse(message: string, status = 500) {
  return jsonResponse({ error: message }, status);
}

// Endpoint 1: Simple health check (no database)
async function handleHealth() {
  return jsonResponse({
    status: "ok",
    timestamp: new Date().toISOString(),
    service: "bun-native",
  });
}

// Endpoint 2: Get single user by ID (simple query)
async function handleGetUser(userId: string) {
  try {
    const result = await pool.query(
      "SELECT id, username, email, created_at, updated_at FROM users WHERE id = $1",
      [userId]
    );

    if (result.rows.length === 0) {
      return errorResponse("User not found", 404);
    }

    return jsonResponse(result.rows[0]);
  } catch (error) {
    console.error("Error fetching user:", error);
    return errorResponse("Database error");
  }
}

// Endpoint 3: Get products with pagination and filtering (moderate complexity)
async function handleGetProducts(url: URL) {
  try {
    const page = parseInt(url.searchParams.get("page") || "1");
    const limit = parseInt(url.searchParams.get("limit") || "10");
    const category = url.searchParams.get("category");
    const offset = (page - 1) * limit;

    let query = "SELECT * FROM products";
    const params: any[] = [];

    if (category) {
      query += " WHERE category = $1";
      params.push(category);
      query += ` ORDER BY created_at DESC LIMIT $2 OFFSET $3`;
      params.push(limit, offset);
    } else {
      query += ` ORDER BY created_at DESC LIMIT $1 OFFSET $2`;
      params.push(limit, offset);
    }

    const result = await pool.query(query, params);

    // Get total count
    const countQuery = category
      ? "SELECT COUNT(*) FROM products WHERE category = $1"
      : "SELECT COUNT(*) FROM products";
    const countParams = category ? [category] : [];
    const countResult = await pool.query(countQuery, countParams);

    return jsonResponse({
      products: result.rows,
      pagination: {
        page,
        limit,
        total: parseInt(countResult.rows[0].count),
      },
    });
  } catch (error) {
    console.error("Error fetching products:", error);
    return errorResponse("Database error");
  }
}

// Endpoint 4: Get order details with joins (complex query)
async function handleGetOrderDetails(orderId: string) {
  try {
    const query = `
      SELECT 
        o.id as order_id,
        o.total_amount,
        o.status,
        o.created_at as order_date,
        u.username,
        u.email,
        json_agg(
          json_build_object(
            'product_id', p.id,
            'product_name', p.name,
            'quantity', oi.quantity,
            'price', oi.price_at_purchase
          )
        ) as items
      FROM orders o
      JOIN users u ON o.user_id = u.id
      JOIN order_items oi ON o.id = oi.order_id
      JOIN products p ON oi.product_id = p.id
      WHERE o.id = $1
      GROUP BY o.id, o.total_amount, o.status, o.created_at, u.username, u.email
    `;

    const result = await pool.query(query, [orderId]);

    if (result.rows.length === 0) {
      return errorResponse("Order not found", 404);
    }

    return jsonResponse(result.rows[0]);
  } catch (error) {
    console.error("Error fetching order details:", error);
    return errorResponse("Database error");
  }
}

// Endpoint 5: Create new order with items (complex transaction)
async function handleCreateOrder(request: Request) {
  const client = await pool.connect();
  
  try {
    const body = await request.json();
    const { user_id, items } = body;

    if (!user_id || !items || !Array.isArray(items) || items.length === 0) {
      return errorResponse("Invalid request body", 400);
    }

    await client.query("BEGIN");

    // Calculate total amount
    let totalAmount = 0;
    for (const item of items) {
      const productResult = await client.query(
        "SELECT price, stock_quantity FROM products WHERE id = $1",
        [item.product_id]
      );

      if (productResult.rows.length === 0) {
        await client.query("ROLLBACK");
        return errorResponse(`Product ${item.product_id} not found`, 404);
      }

      const product = productResult.rows[0];
      if (product.stock_quantity < item.quantity) {
        await client.query("ROLLBACK");
        return errorResponse(
          `Insufficient stock for product ${item.product_id}`,
          400
        );
      }

      totalAmount += parseFloat(product.price) * item.quantity;

      // Update stock
      await client.query(
        "UPDATE products SET stock_quantity = stock_quantity - $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2",
        [item.quantity, item.product_id]
      );
    }

    // Create order
    const orderResult = await client.query(
      "INSERT INTO orders (user_id, total_amount, status) VALUES ($1, $2, $3) RETURNING id",
      [user_id, totalAmount.toFixed(2), "pending"]
    );

    const orderId = orderResult.rows[0].id;

    // Create order items
    for (const item of items) {
      const productResult = await client.query(
        "SELECT price FROM products WHERE id = $1",
        [item.product_id]
      );
      
      await client.query(
        "INSERT INTO order_items (order_id, product_id, quantity, price_at_purchase) VALUES ($1, $2, $3, $4)",
        [orderId, item.product_id, item.quantity, productResult.rows[0].price]
      );
    }

    await client.query("COMMIT");

    return jsonResponse(
      {
        order_id: orderId,
        total_amount: totalAmount.toFixed(2),
        status: "pending",
        message: "Order created successfully",
      },
      201
    );
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Error creating order:", error);
    return errorResponse("Database error");
  } finally {
    client.release();
  }
}

// Main server
const server = serve({
  port: process.env.PORT || 3000,
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // Route handling
    if (path === "/health" && method === "GET") {
      return handleHealth();
    }

    if (path.startsWith("/users/") && method === "GET") {
      const userId = path.split("/")[2];
      return handleGetUser(userId);
    }

    if (path === "/products" && method === "GET") {
      return handleGetProducts(url);
    }

    if (path.startsWith("/orders/") && method === "GET") {
      const orderId = path.split("/")[2];
      return handleGetOrderDetails(orderId);
    }

    if (path === "/orders" && method === "POST") {
      return handleCreateOrder(request);
    }

    return errorResponse("Not found", 404);
  },
});

console.log(`Bun native server running on http://localhost:${server.port}`);

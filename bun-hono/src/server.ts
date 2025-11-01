import { Hono } from "hono";
import { Pool } from "pg";

const app = new Hono();

// Database connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || "postgresql://benchmarkuser:benchmarkpass@localhost:5432/benchmarkdb",
  max: 20,
});

// Endpoint 1: Health check
app.get("/health", (c) => {
  return c.json({
    status: "ok",
    timestamp: new Date().toISOString(),
    service: "bun-hono",
  });
});

// Endpoint 2: Get single user by ID
app.get("/users/:id", async (c) => {
  try {
    const userId = c.req.param("id");
    const result = await pool.query(
      "SELECT id, username, email, created_at, updated_at FROM users WHERE id = $1",
      [userId]
    );

    if (result.rows.length === 0) {
      return c.json({ error: "User not found" }, 404);
    }

    return c.json(result.rows[0]);
  } catch (error) {
    console.error("Error fetching user:", error);
    return c.json({ error: "Database error" }, 500);
  }
});

// Endpoint 3: Get products with pagination and filtering
app.get("/products", async (c) => {
  try {
    const page = parseInt(c.req.query("page") || "1");
    const limit = parseInt(c.req.query("limit") || "10");
    const category = c.req.query("category");
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

    return c.json({
      products: result.rows,
      pagination: {
        page,
        limit,
        total: parseInt(countResult.rows[0].count),
      },
    });
  } catch (error) {
    console.error("Error fetching products:", error);
    return c.json({ error: "Database error" }, 500);
  }
});

// Endpoint 4: Get order details with joins
app.get("/orders/:id", async (c) => {
  try {
    const orderId = c.req.param("id");
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
      return c.json({ error: "Order not found" }, 404);
    }

    return c.json(result.rows[0]);
  } catch (error) {
    console.error("Error fetching order details:", error);
    return c.json({ error: "Database error" }, 500);
  }
});

// Endpoint 5: Create new order with items
app.post("/orders", async (c) => {
  const client = await pool.connect();

  try {
    const body = await c.req.json();
    const { user_id, items } = body;

    if (!user_id || !items || !Array.isArray(items) || items.length === 0) {
      return c.json({ error: "Invalid request body" }, 400);
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
        return c.json({ error: `Product ${item.product_id} not found` }, 404);
      }

      const product = productResult.rows[0];
      if (product.stock_quantity < item.quantity) {
        await client.query("ROLLBACK");
        return c.json(
          { error: `Insufficient stock for product ${item.product_id}` },
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

    return c.json(
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
    return c.json({ error: "Database error" }, 500);
  } finally {
    client.release();
  }
});

// Start server
const port = process.env.PORT || 3002;
console.log(`Bun + Hono server running on http://localhost:${port}`);

export default {
  port,
  fetch: app.fetch,
};

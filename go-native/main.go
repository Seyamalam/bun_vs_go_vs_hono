package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	_ "github.com/lib/pq"
)

var db *sql.DB

// Response helpers
func jsonResponse(w http.ResponseWriter, data interface{}, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func errorResponse(w http.ResponseWriter, message string, status int) {
	jsonResponse(w, map[string]string{"error": message}, status)
}

// Endpoint 1: Health check
func handleHealth(w http.ResponseWriter, r *http.Request) {
	jsonResponse(w, map[string]interface{}{
		"status":    "ok",
		"timestamp": time.Now().Format(time.RFC3339),
		"service":   "go-native",
	}, http.StatusOK)
}

// Endpoint 2: Get single user
func handleGetUser(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(r.URL.Path, "/")
	if len(parts) < 3 {
		errorResponse(w, "Invalid user ID", http.StatusBadRequest)
		return
	}
	userId := parts[2]

	var user struct {
		ID        int       `json:"id"`
		Username  string    `json:"username"`
		Email     string    `json:"email"`
		CreatedAt time.Time `json:"created_at"`
		UpdatedAt time.Time `json:"updated_at"`
	}

	err := db.QueryRow(
		"SELECT id, username, email, created_at, updated_at FROM users WHERE id = $1",
		userId,
	).Scan(&user.ID, &user.Username, &user.Email, &user.CreatedAt, &user.UpdatedAt)

	if err == sql.ErrNoRows {
		errorResponse(w, "User not found", http.StatusNotFound)
		return
	}
	if err != nil {
		log.Println("Error fetching user:", err)
		errorResponse(w, "Database error", http.StatusInternalServerError)
		return
	}

	jsonResponse(w, user, http.StatusOK)
}

// Endpoint 3: Get products with pagination
func handleGetProducts(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	page, _ := strconv.Atoi(query.Get("page"))
	if page < 1 {
		page = 1
	}
	limit, _ := strconv.Atoi(query.Get("limit"))
	if limit < 1 {
		limit = 10
	}
	category := query.Get("category")
	offset := (page - 1) * limit

	var rows *sql.Rows
	var err error
	var countRow *sql.Row

	if category != "" {
		rows, err = db.Query(
			"SELECT * FROM products WHERE category = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3",
			category, limit, offset,
		)
		countRow = db.QueryRow("SELECT COUNT(*) FROM products WHERE category = $1", category)
	} else {
		rows, err = db.Query(
			"SELECT * FROM products ORDER BY created_at DESC LIMIT $1 OFFSET $2",
			limit, offset,
		)
		countRow = db.QueryRow("SELECT COUNT(*) FROM products")
	}

	if err != nil {
		log.Println("Error fetching products:", err)
		errorResponse(w, "Database error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Product struct {
		ID            int       `json:"id"`
		Name          string    `json:"name"`
		Description   *string   `json:"description"`
		Price         float64   `json:"price"`
		StockQuantity int       `json:"stock_quantity"`
		Category      *string   `json:"category"`
		CreatedAt     time.Time `json:"created_at"`
		UpdatedAt     time.Time `json:"updated_at"`
	}

	products := []Product{}
	for rows.Next() {
		var p Product
		err := rows.Scan(&p.ID, &p.Name, &p.Description, &p.Price, &p.StockQuantity, &p.Category, &p.CreatedAt, &p.UpdatedAt)
		if err != nil {
			log.Println("Error scanning product:", err)
			continue
		}
		products = append(products, p)
	}

	var total int
	countRow.Scan(&total)

	jsonResponse(w, map[string]interface{}{
		"products": products,
		"pagination": map[string]int{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	}, http.StatusOK)
}

// Endpoint 4: Get order details with joins
func handleGetOrderDetails(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(r.URL.Path, "/")
	if len(parts) < 3 {
		errorResponse(w, "Invalid order ID", http.StatusBadRequest)
		return
	}
	orderId := parts[2]

	queryStr := `
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
	`

	var order struct {
		OrderID     int             `json:"order_id"`
		TotalAmount float64         `json:"total_amount"`
		Status      string          `json:"status"`
		OrderDate   time.Time       `json:"order_date"`
		Username    string          `json:"username"`
		Email       string          `json:"email"`
		Items       json.RawMessage `json:"items"`
	}

	err := db.QueryRow(queryStr, orderId).Scan(
		&order.OrderID, &order.TotalAmount, &order.Status, &order.OrderDate,
		&order.Username, &order.Email, &order.Items,
	)

	if err == sql.ErrNoRows {
		errorResponse(w, "Order not found", http.StatusNotFound)
		return
	}
	if err != nil {
		log.Println("Error fetching order details:", err)
		errorResponse(w, "Database error", http.StatusInternalServerError)
		return
	}

	jsonResponse(w, order, http.StatusOK)
}

// Endpoint 5: Create new order
func handleCreateOrder(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		errorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var body struct {
		UserID int `json:"user_id"`
		Items  []struct {
			ProductID int `json:"product_id"`
			Quantity  int `json:"quantity"`
		} `json:"items"`
	}

	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		errorResponse(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	if body.UserID == 0 || len(body.Items) == 0 {
		errorResponse(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	tx, err := db.Begin()
	if err != nil {
		log.Println("Error starting transaction:", err)
		errorResponse(w, "Database error", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Calculate total and check stock
	var totalAmount float64
	for _, item := range body.Items {
		var price float64
		var stock int
		err := tx.QueryRow(
			"SELECT price, stock_quantity FROM products WHERE id = $1",
			item.ProductID,
		).Scan(&price, &stock)

		if err == sql.ErrNoRows {
			errorResponse(w, fmt.Sprintf("Product %d not found", item.ProductID), http.StatusNotFound)
			return
		}
		if err != nil {
			log.Println("Error fetching product:", err)
			errorResponse(w, "Database error", http.StatusInternalServerError)
			return
		}

		if stock < item.Quantity {
			errorResponse(w, fmt.Sprintf("Insufficient stock for product %d", item.ProductID), http.StatusBadRequest)
			return
		}

		totalAmount += price * float64(item.Quantity)

		// Update stock
		_, err = tx.Exec(
			"UPDATE products SET stock_quantity = stock_quantity - $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2",
			item.Quantity, item.ProductID,
		)
		if err != nil {
			log.Println("Error updating stock:", err)
			errorResponse(w, "Database error", http.StatusInternalServerError)
			return
		}
	}

	// Create order
	var orderId int
	err = tx.QueryRow(
		"INSERT INTO orders (user_id, total_amount, status) VALUES ($1, $2, $3) RETURNING id",
		body.UserID, totalAmount, "pending",
	).Scan(&orderId)

	if err != nil {
		log.Println("Error creating order:", err)
		errorResponse(w, "Database error", http.StatusInternalServerError)
		return
	}

	// Create order items
	for _, item := range body.Items {
		var price float64
		tx.QueryRow("SELECT price FROM products WHERE id = $1", item.ProductID).Scan(&price)

		_, err = tx.Exec(
			"INSERT INTO order_items (order_id, product_id, quantity, price_at_purchase) VALUES ($1, $2, $3, $4)",
			orderId, item.ProductID, item.Quantity, price,
		)
		if err != nil {
			log.Println("Error creating order item:", err)
			errorResponse(w, "Database error", http.StatusInternalServerError)
			return
		}
	}

	if err := tx.Commit(); err != nil {
		log.Println("Error committing transaction:", err)
		errorResponse(w, "Database error", http.StatusInternalServerError)
		return
	}

	jsonResponse(w, map[string]interface{}{
		"order_id":     orderId,
		"total_amount": fmt.Sprintf("%.2f", totalAmount),
		"status":       "pending",
		"message":      "Order created successfully",
	}, http.StatusCreated)
}

func main() {
	// Database connection
	connStr := os.Getenv("DATABASE_URL")
	if connStr == "" {
		connStr = "postgresql://benchmarkuser:benchmarkpass@localhost:5432/benchmarkdb?sslmode=disable"
	}

	var err error
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal("Error connecting to database:", err)
	}
	defer db.Close()

	db.SetMaxOpenConns(20)
	db.SetMaxIdleConns(10)

	// Routes
	http.HandleFunc("/health", handleHealth)
	http.HandleFunc("/users/", handleGetUser)
	http.HandleFunc("/products", handleGetProducts)
	http.HandleFunc("/orders/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			handleGetOrderDetails(w, r)
		}
	})
	http.HandleFunc("/orders", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			handleCreateOrder(w, r)
		} else {
			errorResponse(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "3001"
	}

	log.Printf("Go native server running on http://localhost:%s\n", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

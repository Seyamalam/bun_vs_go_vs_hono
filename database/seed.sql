-- Seed data for testing and benchmarking

-- Insert sample users
INSERT INTO users (username, email) VALUES
    ('john_doe', 'john@example.com'),
    ('jane_smith', 'jane@example.com'),
    ('bob_wilson', 'bob@example.com'),
    ('alice_jones', 'alice@example.com'),
    ('charlie_brown', 'charlie@example.com'),
    ('diana_prince', 'diana@example.com'),
    ('eve_martin', 'eve@example.com'),
    ('frank_castle', 'frank@example.com'),
    ('grace_hopper', 'grace@example.com'),
    ('henry_ford', 'henry@example.com')
ON CONFLICT (username) DO NOTHING;

-- Insert sample products
INSERT INTO products (name, description, price, stock_quantity, category) VALUES
    ('Laptop Pro', 'High-performance laptop for professionals', 1299.99, 50, 'Electronics'),
    ('Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 200, 'Electronics'),
    ('Mechanical Keyboard', 'RGB mechanical gaming keyboard', 89.99, 150, 'Electronics'),
    ('USB-C Cable', 'Fast charging USB-C cable', 12.99, 500, 'Accessories'),
    ('Laptop Stand', 'Adjustable aluminum laptop stand', 49.99, 100, 'Accessories'),
    ('Webcam HD', '1080p HD webcam with microphone', 79.99, 75, 'Electronics'),
    ('Desk Lamp', 'LED desk lamp with adjustable brightness', 34.99, 120, 'Office'),
    ('Notebook Set', 'Set of 3 premium notebooks', 19.99, 300, 'Office'),
    ('Pen Collection', 'Premium pen collection (5 pens)', 24.99, 250, 'Office'),
    ('Monitor Stand', 'Wooden monitor stand with storage', 39.99, 80, 'Accessories'),
    ('Phone Holder', 'Adjustable phone holder', 14.99, 400, 'Accessories'),
    ('Headphones Pro', 'Noise-cancelling headphones', 199.99, 60, 'Electronics'),
    ('Bluetooth Speaker', 'Portable Bluetooth speaker', 59.99, 150, 'Electronics'),
    ('Power Bank', '20000mAh portable power bank', 44.99, 180, 'Electronics'),
    ('Screen Cleaner', 'Premium screen cleaning kit', 9.99, 600, 'Accessories')
ON CONFLICT DO NOTHING;

-- Insert sample orders
INSERT INTO orders (user_id, total_amount, status) VALUES
    (1, 1329.98, 'completed'),
    (2, 89.99, 'completed'),
    (3, 149.97, 'pending'),
    (1, 49.99, 'completed'),
    (4, 329.96, 'shipped'),
    (5, 12.99, 'completed'),
    (2, 134.98, 'completed'),
    (6, 199.99, 'pending'),
    (7, 94.98, 'completed'),
    (3, 264.97, 'shipped')
ON CONFLICT DO NOTHING;

-- Insert sample order items
INSERT INTO order_items (order_id, product_id, quantity, price_at_purchase) VALUES
    (1, 1, 1, 1299.99),
    (1, 2, 1, 29.99),
    (2, 3, 1, 89.99),
    (3, 4, 3, 12.99),
    (3, 8, 1, 19.99),
    (3, 9, 4, 24.99),
    (4, 5, 1, 49.99),
    (5, 6, 2, 79.99),
    (5, 7, 2, 34.99),
    (5, 10, 2, 39.99),
    (6, 4, 1, 12.99),
    (7, 7, 1, 34.99),
    (7, 8, 5, 19.99),
    (8, 12, 1, 199.99),
    (9, 11, 2, 14.99),
    (9, 15, 5, 9.99),
    (10, 13, 2, 59.99),
    (10, 14, 3, 44.99)
ON CONFLICT DO NOTHING;

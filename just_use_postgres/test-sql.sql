-- Create table
CREATE TABLE
    customer (
        customer_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        first_name VARCHAR(100) NOT NULL,
        last_name VARCHAR(100) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

CREATE INDEX idx_customer_last_name ON customer (last_name);

CREATE INDEX idx_customer_full_name ON customer (last_name, first_name);

-- ALTER TABLE customer
-- ADD COLUMN column_name data_type;
-- Update table
ALTER TABLE customer
ADD COLUMN country VARCHAR(50);

-- Add new table with one to many 
CREATE TABLE
    sales_order (
        order_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        customer_id INTEGER NOT NULL,
        order_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        total_amount NUMERIC(12, 2) NOT NULL,
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        -- Foreign key: 1 customer -> many orders
        CONSTRAINT fk_sales_order_customer FOREIGN KEY (customer_id) REFERENCES customer (customer_id) ON DELETE CASCADE
    );

-- Step 1: Create an index
CREATE INDEX idx_sales_order_customer_id ON sales_order (customer_id);

-- Step 2: Add the foreign key constraint
ALTER TABLE sales_order ADD CONSTRAINT fk_sales_order_customer FOREIGN KEY (customer_id) REFERENCES customer (customer_id) ON DELETE CASCADE;

-- Update table and add Relation and index
ALTER TABLE sales_order
ADD COLUMN sales_person_id INTEGER;

-- Add foreign key into table
ALTER TABLE sales_order ADD CONSTRAINT fk_sales_order_sales_person FOREIGN KEY (sales_person_id) REFERENCES sales_person (sales_person_id) ON DELETE RESTRICT;

-- Add Index 
CREATE INDEX idx_sales_order_sales_person ON sales_order (sales_person_id);

-- 1 to 1 
CREATE TABLE
    customer_detail (
        id SERIAL PRIMARY KEY,
        customer_id INTEGER UNIQUE NOT NULL,
        date_of_birth DATE,
        address TEXT,
        FOREIGN KEY (customer_id) REFERENCES customer (customer_id) ON DELETE CASCADE
    );

-- Many to Many
CREATE TABLE
    sales_order_product (
        sales_order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        price NUMERIC(12, 2) NOT NULL, -- цена на момент заказа
        PRIMARY KEY (sales_order_id, product_id),
        FOREIGN KEY (sales_order_id) REFERENCES sales_order (order_id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES product (product_id) ON DELETE RESTRICT
    );

CREATE INDEX idx_sop_order ON sales_order_product (sales_order_id);

CREATE INDEX idx_sop_product ON sales_order_product (product_id);

---- 
CREATE TABLE
    orders (id SERIAL PRIMARY KEY, details JSONB);

CREATE INDEX idx_orders_details ON orders USING GIN (details);
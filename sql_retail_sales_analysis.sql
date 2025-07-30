-- SQL Retail Sales Analysis 

CREATE DATABASE bike_store_db;

-- Create Table "Customers"

DROP TABLE IF EXISTS customers;
CREATE TABLE customers
(
	customer_id	INT PRIMARY KEY,
	first_name VARCHAR(15),
	last_name VARCHAR(15),	
	phone VARCHAR(15),
	email VARCHAR(40),	
	street VARCHAR(40),	
	city VARCHAR(30),	
	state VARCHAR(5), 	
	zip_code VARCHAR(10)
);

-- Create Table "Stores"

DROP TABLE IF EXISTS stores;
CREATE TABLE stores
(
	store_id INT PRIMARY KEY,	
	store_name VARCHAR(20),	
	phone VARCHAR(15), 	
	email VARCHAR(25), 	
	street VARCHAR(25), 	
	city VARCHAR(15), 	
	state VARCHAR(5),	
	zip_code VARCHAR(10)
);

-- Create Table "Staffs"

DROP TABLE IF EXISTS staffs;
CREATE TABLE staffs
(
	staff_id INT PRIMARY KEY,	
	first_name VARCHAR(15),	
	last_name VARCHAR(15),	
	email VARCHAR(35),	
	phone VARCHAR(20),	
	active INT,	
	store_id INT,	
	manager_id INT,
	CONSTRAINT fk_store_id FOREIGN KEY (store_id) REFERENCES stores(store_id),
	CONSTRAINT fk_manager_id FOREIGN KEY (manager_id) REFERENCES staffs(staff_id)
);	

-- Create Table "Orders"

DROP TABLE IF EXISTS orders;
CREATE TABLE orders
(
	order_id INT PRIMARY KEY,	
	customer_id	INT,
	order_status INT,	
	order_date DATE,	
	required_date DATE,	
	shipped_date DATE,	
	store_id INT,	
	staff_id INT,
	CONSTRAINT fk_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
	CONSTRAINT fk_store_id FOREIGN KEY (store_id) REFERENCES stores(store_id),
	CONSTRAINT fk_staff_id FOREIGN KEY (staff_id) REFERENCES staffs(staff_id)
);

-- Create Table "Categories"

DROP TABLE IF EXISTS categories;
CREATE TABLE categories
(
	category_id INT PRIMARY KEY,	
	category_name VARCHAR(25)
);	

-- Create table "Brands"

DROP TABLE IF EXISTS brands;
CREATE TABLE brands
(
	brand_id INT PRIMARY KEY,	
	brand_name VARCHAR(15)
);

-- Create table "Products"

DROP TABLE IF EXISTS products;
CREATE TABLE products
(
	product_id INT PRIMARY KEY,	
	product_name VARCHAR(60),	
	brand_id INT,	
	category_id	INT,
	model_year VARCHAR(6),	
	list_price FLOAT,
	CONSTRAINT fk_brand_id FOREIGN KEY (brand_id) REFERENCES brands(brand_id),
	CONSTRAINT fk_category_id FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- Create table "Order Items"

DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items(
	order_id INT,	
	item_id INT,
	PRIMARY KEY (order_id, item_id),
	product_id INT,	
	quantity INT,	
	list_price FLOAT,	
	discount FLOAT,
	CONSTRAINT fk_product_id FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- CREATE table "Stocks"

DROP TABLE IF EXISTS stocks;
CREATE TABLE stocks
(
	store_id INT,	
	product_id INT,
	PRIMARY KEY (store_id, product_id),
	quantity INT,
	CONSTRAINT fk_store_id FOREIGN KEY (store_id) REFERENCES stores(store_id),
	CONSTRAINT fk_product_id FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Data cleaning

SELECT * FROM customers
WHERE
	first_name IS NULL
	OR
	last_name IS NULL
	OR
	phone IS NULL
	OR
	email IS NULL
	OR
	street IS NULL
	OR
	city IS NULL
	OR 
	state IS NULL
	OR
	zip_code IS NULL;

UPDATE customers
SET phone = 'No-Number'
WHERE phone Is Null;

-- Data Analysis and Business Key Problems and Answers

-- Q.1 What are the 5 most recent orders placed?

SELECT
	order_id, order_date
FROM orders
ORDER BY order_date DESC
LIMIT 5;

-- Q.2 Which customers are from San Diego?

SELECT 
	first_name, last_name, city
FROM customers
WHERE city = 'San Diego';

SELECT * FROM products

-- Q.3 Which products have a price range between 800 and 1000 dollars?

SELECT 
	product_name, list_price
FROM products
WHERE list_price BETWEEN 800 and 1000
ORDER BY list_price DESC;

-- Q.4 Which orders have not shipped yet?

SELECT order_id, order_status, shipped_date
FROM orders
WHERE shipped_date IS NULL;

-- Q.5 How many customers placed multiple orders?

SELECT
	CASE
		WHEN orders_per_customer > 1 THEN 'Repeat'
		ELSE 'One-Time'
	END AS customer_type,
	COUNT(*) AS num_customers
FROM (
	SELECT c.customer_id, COUNT(o.order_id) AS orders_per_customer 
	FROM customers AS c
	JOIN orders AS o 
	ON c.customer_id = o.customer_id
	GROUP BY c.customer_id
) customer_orders
GROUP BY customer_type;

-- Q.6 What are the total sales per store and which stores made over $50,000?

SELECT 
	s.store_name,
	SUM(oi.list_price * oi.quantity * (1 - oi.discount)) AS total_sales
FROM stores AS s
JOIN orders AS o 
ON s.store_id = o.store_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY s.store_name
HAVING SUM(oi.list_price * oi.quantity * (1 - oi.discount)) > 50000
ORDER BY total_sales DESC;

-- Q.7 how many orders were placed each month and year?

SELECT
	EXTRACT(YEAR FROM order_date) AS year,
	EXTRACT(MONTH FROM order_date) AS month,
	COUNT(order_id) AS total_orders
FROM orders
GROUP BY year, month
ORDER BY year, month;

-- Q.8 What are the top 5 best-selling products by quantity?

SELECT 
	p.product_name, SUM(oi.quantity) AS total_units_sold
FROM productS AS p	
JOIN 
	order_items AS oi
ON	p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY total_units_sold DESC
LIMIT 5;

-- Q.9 Which products have critically low stock levels across all stores?

SELECT 
	p.product_name, SUM(s.quantity) AS total_stock
FROM products AS p
JOIN stocks AS s 
ON p.product_id = s.product_id
GROUP BY p.product_name
HAVING SUM(s.quantity) < 20
ORDER BY total_stock ASC;

-- Q.10 How many days pass between orders for each customer?

SELECT 
	customer_id,
	order_id,
	order_date,
	LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date,
	order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS days_between_orders
FROM orders
ORDER BY customer_id, order_date;

-- Q.11 Which stores or staff members have the fastest or slowest average shipping times?

SELECT 
 	st.store_name,
 	s.first_name || ' ' || s.last_name AS staff_name,
 	AVG(o.shipped_date - o.order_date) AS avg_shipping_days,
 	RANK() OVER (PARTITION BY o.store_id ORDER BY AVG(o.shipped_date - o.order_date)) AS shipping_speed_rank
FROM orders AS o
JOIN staffs AS s 
ON o.staff_id = s.staff_id
JOIN stores AS st 
ON o.store_id = st.store_id
GROUP BY o.store_id, s.staff_id, st.store_name, staff_name
ORDER BY o.store_id, shipping_speed_rank;

-- Q.12 Which customers have spent the most money overall?

WITH CustomerSpending AS (
	SELECT
	o.customer_id,
	SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent
	FROM orders AS o
	JOIN order_items oi
	ON o.order_id = oi.order_id
	GROUP BY o.customer_id
)

SELECT
	c.first_name || ' ' || c.last_name AS customer_name,
	cs.total_spent
	FROM CustomerSpending AS cs
	JOIN customers c 
	ON cs.customer_id = c.customer_id
	ORDER BY cs.total_spent DESC
	LIMIT 10;

-- Q.13 Which brands generate the most revenue?

WITH BrandRevenue AS (
	SELECT
	p.brand_id,
	SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
	FROM order_items oi
	JOIN products p ON oi.product_id = p.product_id
	GROUP BY p.brand_id
)	

SELECT
	b.brand_name,
	br.total_revenue
FROM BrandRevenue AS br
JOIN brands b ON br.brand_id = b.brand_id
ORDER BY br.total_revenue DESC
LIMIT 10;

-- Q.14 What are the best-selling product categories?

WITH CATEGORYSALES AS (
	SELECT
	p.category_id,
	SUM(oi.quantity) AS total_units_sold
	FROM order_items oi
	JOIN products p
	ON oi.product_id = p.product_id
	GROUP BY p.category_id
)
SELECT
	c.category_name,
	cs.total_units_sold
FROM CategorySales cs
JOIN categories AS C
ON cs.category_id = c.category_id
ORDER BY cs.total_units_sold DESC
LIMIT 10;

-- Q.15 Which products are frequently out of stock?

WITH OutOfStockProducts AS(
	SELECT
		s.store_id,
		p.product_id,
		COUNT(*) AS out_of_stock_count
	FROM stocks AS s
	JOIN products AS p 
	ON s.product_id = p.product_id
	WHERE s.quantity = 0
	GROUP BY s.store_id, p.product_id
)
SELECT 
	st.store_name,
	p.product_name,
	oosp.out_of_stock_count
FROM OutOfStockProducts oosp
JOIN stores AS st
ON oosp.store_id = st.store_id
JOIN products AS p ON oosp.product_id = p.product_id
ORDER BY oosp.out_of_stock_count DESC
LIMIT 10;

-- Q.16 What is the average discount applied per brand?

WITH BrandDiscounts AS(
	SELECT
		p.brand_id,
		AVG(oi.discount) AS avg_discount
	FROM order_items oi
	JOIN products p
	ON oi.product_id = p.product_id
	GROUP BY p.brand_id
)
SELECT 
	b.brand_name,
	bd.avg_discount
FROM BrandDiscounts bd
JOIN brands b 
ON bd.brand_id = b.brand_id
ORDER BY bd.avg_discount DESC;	
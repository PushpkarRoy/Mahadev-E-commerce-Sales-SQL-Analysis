CREATE TABLE customers (
customer_id INT,
customer_name VARCHAR(50),
gender VARCHAR(20),
city VARCHAR(20)
)

CREATE TABLE order_items (
order_item_id INT,
order_id INT,
product_id INT,
quantity INT
)

CREATE TABLE  orders (
order_id INT,
customer_id	INT,
order_date DATE,
total_amount INT
)

CREATE TABLE products (
product_id INT,
product_name VARCHAR(50),
category VARCHAR(50),
price INT
)

-- 🔍Quest1. Top 5 cities by revenue generated in February 2025.

SELECT *,
RANK() OVER(ORDER BY revenue DESC) AS ranking
FROM (
	SELECT city, SUM(total_revenue) AS revenue
	FROM (
		SELECT  order_date,
			   TO_CHAR(order_date, 'Month') AS Month_name,
			   c.city, 
			   (P.price * ot.quantity) AS total_revenue
		     FROM orders AS o
		   JOIN order_items AS ot
		   ON o.order_id = ot.order_id
		 JOIN products AS p
	   ON ot.product_id = p.product_id
	JOIN customers AS c
   ON c.customer_id =  o.customer_id
  WHERE order_date BETWEEN '2025-02-01' AND '2025-02-28'
  ) AS x
 GROUP BY city ) AS z

-- 💸Quest2. Find the average order value per customer (only if they placed > 1 order)

SELECT c.customer_name, 
	   ROUND(AVG(o.total_amount):: NUMERIC, 2) AS avg_amount, 
	   COUNT(o.order_id) AS total_order
FROM customers AS c 
JOIN orders  AS o
		ON c.customer_id = o.customer_id 
GROUP BY c.customer_name 
	HAVING COUNT(o.order_id) > 1
ORDER BY avg_amount DESC

-- 📦Quest3. Which product category had the highest quantity sold in March?

SELECT category, SUM(quantity) AS total_quantity
FROM (
	SELECT p.category, 
		   ot.quantity, 
		   o.order_date
	FROM products AS p
	JOIN order_items AS ot
		ON p.product_id = ot.product_id
	JOIN orders AS o
		ON ot.order_id = o.order_id 
	WHERE order_date 
		BETWEEN '2025-03-01' AND '2025-03-31' ) AS x
GROUP BY category
ORDER BY total_quantity DESC

-- 📈Quest4. Month-over-month sales growth by total revenue

-- SELECT *,
-- ROUND(CUME_DIST() OVER( ORDER BY month_no):: NUMERIC ,2 ) AS difference
-- FROM (
	SELECT EXTRACT(MONTH FROM o.order_date) AS month_no,
		   TO_CHAR(order_date, 'Month') AS Month_name,
		   SUM(ot.quantity * price) AS total_revenue,
		   ROUND(SUM((ot.quantity * price) * 100.0   / 
			                                    (SELECT SUM(ot.quantity * p.price)
												 FROM order_items AS ot
												 JOIN products AS p
												 ON ot.product_id = p.product_id) )::NUMERIC,2)  AS percentage 
	FROM orders AS o
	JOIN order_items AS ot 
	ON o.order_id = ot.order_id
	JOIN products AS p
	ON p.product_id = ot.product_id 
	GROUP BY Month_name, month_no


--  -----------------------------------------------------------------


SELECT 
    month_no,
    month_name,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY month_no) AS previous_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY month_no)) 
        / NULLIF(LAG(total_revenue) OVER (ORDER BY month_no), 0) * 100, 
        2
    ) AS growth_percentage
FROM (
    SELECT 
        EXTRACT(MONTH FROM o.order_date) AS month_no,
        TO_CHAR(o.order_date, 'Month') AS month_name,
        SUM(oi.quantity * p.price) AS total_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY month_no, month_name
) AS monthly_sales
ORDER BY month_no;


-- 📊Quest5. Top 3 customers by total spend in the entire quarter

SELECT c.customer_name, 
	   SUM(ot.quantity * p.price) total_spend
FROM products  AS p
	JOIN order_items AS ot
		ON p.product_id = ot.product_id 
				JOIN orders AS o
					ON o.order_id = ot.order_id 
				JOIN customers AS c
			ON c.customer_id = o.customer_id
		GROUP BY c.customer_name 
	ORDER BY total_spend DESC
LIMIT  3


-- 📉Quest6. List customers who placed only 20 or less then 20 order in 3 months

SELECT c.customer_name, 
	   COUNT(ot.order_id) AS total_order 
FROM order_itemS AS ot
JOIN orders AS o
ON o.order_id = ot.order_id
JOIN customers AS c
ON o.customer_id = c.customer_id 
GROUP BY c.customer_name
HAVING COUNT(ot.order_id) <= 20

-- 📍Quest7. Which city had the highest number of unique customers in Jan?

SELECT c.city, COUNT(DISTINCT o.customer_id) AS unique_customers
	FROM orders AS o
	JOIN customers AS c
	ON c.customer_id = o.customer_id 
	GROUP BY c.city

-- 🧾Quest8. Product with highest total revenue (price × quantity)

SELECT p.product_name, SUM(p.price * ot.quantity) AS total_revenue
FROM products AS p
JOIN order_items AS ot
ON p.product_id = ot.product_id 
GROUP BY p.product_name 
ORDER BY total_revenue DESC
LIMIT 1 

-- 📅Quest9. What day of the week had the highest average order value?

SELECT TO_CHAR(order_date, 'day') AS order_day, ROUND(AVG((p.price * ot.quantity)):: NUMERIC ,2 ) AS Avg_order
FROM orders AS o
JOIN order_items AS ot
ON o.order_id = ot.order_id
JOIN products AS p
ON p.product_id = ot.product_id
GROUP BY order_day
ORDER BY Avg_order DESC


-- 📚Quest10. Compare sales of Electronics vs Fashion category month-wise


	SELECT *
	FROM (
		SELECT  EXTRACT(MONTH FROM order_date) AS month_no,
			    TO_CHAR(order_date, 'Month') AS order_month, p.category, 
				SUM(p.price * ot.quantity ) AS total_revenue, 
				ROUND(SUM(p.price * ot.quantity) * 100.0 / ( SELECT SUM(p.price * ot.quantity) 
				                                              FROM products AS p
													          JOIN order_items AS ot
													          ON p.product_id = ot.product_id  ):: NUMERIC ,2 ) 
															  AS percentage 
		FROM orders AS o
		JOIN order_items AS ot
			ON o.order_id = ot.order_id
		JOIN products AS p
			ON p.product_id = ot.product_id 
		GROUP BY month_no, order_month, p.category ) AS x
	WHERE category = 'Electronics' OR category = 'Fashion' 
ORDER BY month_no

-- 📌Quest11. List orders that had more than 3 items in them

SELECT order_id, COUNT(product_id ) AS total_item
FROM order_items 
GROUP BY order_id 
HAVING COUNT(product_id ) > 3

-- 📆Quest12. Which customers placed orders in all 3 months?

SELECT 
    c.customer_id,
    c.customer_name
FROM customers c
JOIN orders o 
ON c.customer_id = o.customer_id
WHERE EXTRACT(MONTH FROM o.order_date) IN (1, 2, 3)
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT EXTRACT(MONTH FROM o.order_date)) = 3; 

-- 🔄Quest13. Find the reorder rate of customers (customers who placed ≥ 2 orders)

SELECT 
    ROUND(COUNT(DISTINCT customer_id) * 100.0 / 
    (SELECT COUNT(*) FROM customers):: NUMERIC, 2) AS reorder_rate_percentage
FROM orders
GROUP BY customer_id
HAVING COUNT(order_id) >= 2;

-- 📥Quest14. Identify customers who placed an order in Jan but not in Feb or Mar

SELECT DISTINCT c.customer_id, c.customer_name
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE EXTRACT(MONTH FROM o.order_date) = 1
  AND c.customer_id NOT IN (
      SELECT customer_id
      FROM orders
      WHERE EXTRACT(MONTH FROM order_date) IN (2, 3)
  );

-- 🛑Quest15. Detect and list any duplicate orders (same customer, same amount, same date)

SELECT 
    customer_id,
    order_date,
    total_amount,
    COUNT(*) AS duplicate_count
FROM orders
GROUP BY customer_id, order_date, total_amount
HAVING COUNT(*) > 1;
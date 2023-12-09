/*
Bike Sales Data Exploration

Skills used: Joins, Aggregate Functions, Window Functions, Converting Data Types
*/

--Top 3 brands by volume:

SELECT
	COUNT(*) AS num_orders,
	b.brand_name
FROM
	order_items o
LEFT JOIN
	products pr ON
	o.product_id = pr.product_id
LEFT JOIN
	brands b ON
	pr.brand_id = b.brand_id
GROUP BY
	b.brand_name
ORDER BY
	num_orders DESC
LIMIT 3;

--Top 3 brands by sum of sales:

SELECT
	ROUND(SUM(o.list_price * (1 - o.discount)), 2) AS sales_total,
	b.brand_name
FROM
	order_items o
LEFT JOIN
	products pr ON
	o.product_id = pr.product_id
LEFT JOIN
	brands b ON
	pr.brand_id = b.brand_id
GROUP BY
	b.brand_name
ORDER BY
	sales_total DESC
LIMIT 3;

--Percentage of total sales by brand:

SELECT
	ROUND(SUM(o.list_price * (1 - o.discount))/ (SELECT SUM(list_price * (1 - discount)) FROM order_items) * 100, 2) as pct_sales,
	b.brand_name
FROM
	order_items o
LEFT JOIN
	products pr ON
	o.product_id = pr.product_id
LEFT JOIN
	brands b ON
	pr.brand_id = b.brand_id
GROUP BY
	b.brand_name
ORDER BY
	pct_sales DESC;

--Total orders by staff member:

SELECT
	COUNT(*) AS total_orders,
	staff_id,
	staff_name
FROM
	(SELECT
		DISTINCT(oi.order_id) AS dist_order,
		o.staff_id,
		CONCAT(s.first_name, ' ', s.last_name) AS staff_name
	FROM
		order_items oi
	LEFT JOIN
		orders o ON
		oi.order_id = o.order_id
	LEFT JOIN
		staffs s ON
		o.staff_id = s.staff_id
	) AS staff_orders
GROUP BY
	staff_id,
	staff_name
ORDER BY
	total_orders DESC;

--Total sales by staff:

SELECT
	staff_name,
	ROUND(SUM(total), 2) AS sales_total
FROM
	(SELECT
		oi.list_price * (1 - oi.discount) as total,
		s.staff_id,
		CONCAT(s.first_name, ' ', s.last_name) AS staff_name
	FROM
		order_items oi
	LEFT JOIN
		orders o ON
		oi.order_id = o.order_id
	LEFT JOIN
		staffs s ON
		o.staff_id = s.staff_id
	 ) AS sales_by_staff
GROUP BY
	staff_id,
	staff_name
ORDER BY
	sales_total DESC;

--Sales Metrics by Staff:

SELECT
	staff_name,
	ROUND(SUM(total), 2) AS sales_total,
	COUNT(DISTINCT(order_id)) AS total_orders,
	ROUND(ROUND(SUM(total), 2) / COUNT(DISTINCT(order_id)), 2) AS average_order_value,
	ROUND(CAST(COUNT(*) AS numeric) / CAST(COUNT(DISTINCT(order_id)) AS numeric), 2) AS units_per_transaction
FROM
	(SELECT
	 	oi.order_id,
		oi.list_price * (1 - oi.discount) as total,
		CONCAT(s.first_name, ' ', s.last_name) AS staff_name
	FROM
		order_items oi
	LEFT JOIN
		orders o ON
		oi.order_id = o.order_id
	LEFT JOIN
		staffs s ON
		o.staff_id = s.staff_id
	 ) AS sales_by_staff
GROUP BY
	staff_name
ORDER BY
	sales_total DESC;

--Sales and increase YOY:

SELECT
	sales,
	CONCAT(ROUND((sales / LAG(sales, 1) OVER(ORDER BY sales_year) * 100 - 100), 2), '%') AS pct_change_yoy,
	sales_year
FROM
	(
	SELECT
		ROUND(SUM(oi.list_price * (1 - oi.discount)), 2) AS sales,
		LEFT(CAST(o.order_date AS varchar), 4) AS sales_year
	FROM
		order_items oi
	LEFT JOIN
		orders o ON
		oi.order_id = o.order_id
	GROUP BY
		sales_year
	ORDER BY
		sales_year
	) AS sales_by_year;

--Sales by quarter w/ year over year growth:

SELECT
	sales,
	ROUND(sales / LAG(sales, 4) OVER(ORDER BY sales_year) * 100 - 100, 2) AS pct_growth_yoy,
	quarter,
	sales_year
FROM
	(
	SELECT
		SUM(oi.list_price * (1 - discount)) AS sales,
		CASE
			WHEN EXTRACT(MONTH FROM order_date) IN (1, 2, 3) THEN '1'
			WHEN EXTRACT(MONTH FROM order_date) IN (4, 5, 6) THEN '2'
			WHEN EXTRACT(MONTH FROM order_date) IN (7, 8, 9) THEN '3'
			WHEN EXTRACT(MONTH FROM order_date) IN (10, 11, 12) THEN '4'
		END AS quarter,
		EXTRACT(YEAR FROM order_date) AS sales_year
	FROM
		order_items oi
	LEFT JOIN
		orders o ON
		oi.order_id = o.order_id
	GROUP BY
		quarter,
		sales_year
	ORDER BY
		sales_year,
		quarter
	) AS sales_by_quarter
ORDER BY
	sales_year,
	quarter;


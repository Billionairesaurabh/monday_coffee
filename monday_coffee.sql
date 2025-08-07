
CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(25),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);

CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);

CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

SELECT * FROM monday_coffee_db.customers;
select * from city;
select * from customers;
select * from products;
select * from sales;

-- Reports & Data Analysis

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
select city_name,
round((population *.25)/1000000,2)  as coffee_consumers_in_millions,
city_rank
from city
order by population desc;

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
select CI.CITY_NAME,
sum(S.TOTAL) AS TOTAL_REVENUE
 from sales AS S
 JOIN CUSTOMERS AS C
 ON S.customer_id = C.customer_id
 JOIN CITY AS CI
 ON CI.CITY_ID = C.CITY_ID
WHERE year(S.SALE_DATE)  = 2023
AND
quarter(S.SALE_DATE) = 4
GROUP BY CI.CITY_NAME
ORDER BY 2 DESC;
-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?
SELECT p.product_name,
count(s.sale_id) as total_orders
 from products as p
left join
sales as s
on s.product_id = p.product_id
group by 1
order by total_orders desc;
-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?
select CI.CITY_NAME,
sum(S.TOTAL) AS TOTAL_REVENUE,
count(s.customer_id) as total_customer,
round(sum(s.total)/count(distinct s.customer_id),2) as per_customer_avg_sales
 from sales AS S
 JOIN CUSTOMERS AS C
 ON S.customer_id = C.customer_id
 JOIN CITY AS CI
 ON CI.CITY_ID = C.CITY_ID
GROUP BY CI.CITY_NAME
ORDER BY 2 DESC;
-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name;

-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
select * from -- tablename
(
select 
ci.city_name,p.product_name,count(s.sale_id) as total_orders,
dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc) as rankk
 from sales as s
join products as p 
on s.product_id = p.product_id
join customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1,2
-- order by 1 , 3 desc;
) as t1
where rankk <=3;
-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
select ci.city_name,
count(distinct c.customer_id) as unique_customers
from city as ci
join customers as c
on c.city_id = ci.city_id
join sales as s
on s.customer_id = c.customer_id
where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by 1;

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions

WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2
        ) AS avg_sale_pr_cx
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent
    FROM city
)
SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_cx,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent / ct.total_cx,
        2
    ) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct ON cr.city_name = ct.city_name
ORDER BY ct.avg_sale_pr_cx DESC;




-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sales AS (
    SELECT 
        ci.city_name,
        MONTH(s.sale_date) AS month,
        YEAR(s.sale_date) AS year,
        SUM(s.total) AS total_sale
    FROM sales AS s
    JOIN customers AS c ON c.customer_id = s.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, MONTH(s.sale_date), YEAR(s.sale_date)
),
growth_ratio AS (
    SELECT
        city_name,
        month,
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale, 1) OVER (PARTITION BY city_name ORDER BY year, month) AS last_month_sale
    FROM monthly_sales
)

SELECT
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND(
        (cr_month_sale - last_month_sale) / last_month_sale * 100,
        2
    ) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL;


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2
        ) AS avg_sale_pr_cx
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumer_in_millions
    FROM city
)
SELECT 
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_cx,
    cr.estimated_coffee_consumer_in_millions,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent / ct.total_cx,
        2
    ) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct ON cr.city_name = ct.city_name
ORDER BY ct.total_revenue DESC;


/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k





































































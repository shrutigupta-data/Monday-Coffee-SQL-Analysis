# SQL PROJECT 7 - Monday Coffee Analysis
USE Projects;
SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM monco_customers;
SELECT * FROM sales;

-- Verifying the dataset
# Missing values
SELECT *
FROM city
WHERE city_name IS NULL;

# Duplicate records
SELECT sale_id, COUNT(*)
FROM sales
GROUP BY sale_id
HAVING COUNT(*) > 1;

# Invalid foreign keys
SELECT *
FROM sales s
LEFT JOIN monco_customers  c
ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

# Invalid dates
SELECT *
FROM sales
WHERE sale_date IS NULL;

-- Reports & Data Analysis
#1. Coffee Consumers Count
## How many people in each city are estimated to consume coffee, given that 25% of the population does?
select city_name, round(population * 25/100) as coffee_drinkers from city;

#2. Total Revenue from Coffee Sales
## What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
select sum(total) as total_revenue from sales
where year(sale_date) = '2023' and month(sale_date) in ('10','11','12');

#3. Sales Count for Each Product
## How many units of each coffee product have been sold?
select t1.product_id,t1.product_name, count(*) as quantity_sold from products t1
join sales t2
on t1.product_id = t2.product_id
group by t1.product_id, t1.product_name;

#4. Average Sales Amount per City
## What is the average sales amount per customer in each city?
WITH customer_sales AS (
    SELECT
        c.customer_id,
        ci.city_name,
        SUM(s.total) AS total_spent
    FROM sales s
    JOIN monco_customers c
        ON s.customer_id = c.customer_id
    JOIN city ci
        ON c.city_id = ci.city_id
    GROUP BY c.customer_id, ci.city_name
)

SELECT
    city_name,
    ROUND(AVG(total_spent), 2) AS avg_sales_per_customer
FROM customer_sales
GROUP BY city_name;

#5. City Population and Coffee Consumers
## Provide a list of cities along with their populations and estimated coffee consumers.
select city_name,population, round(population * 0.25) as coffee_drinkers from city;

#6. Top Selling Products by City
## What are the top 3 selling products in each city based on sales volume?
select * from (SELECT
    city_name,
    product_name,
    sales_volume,
    RANK() OVER (partition by city_name
    ORDER BY sales_volume DESC) as product_rank
FROM
(SELECT t3.city_name,t4.product_name,sum(t1.total) as sales_volume
FROM sales t1
JOIN monco_customers t2
ON t1.customer_id = t2.customer_id
JOIN city t3
ON t2.city_id = t3.city_id
JOIN products t4
ON t1.product_id = t4.product_id
group by t3.city_name,t4.product_name) AS sales_vol) AS ranked_products
WHERE product_rank <= 3;

#7. Customer Segmentation by City
## How many unique customers are there in each city who have purchased coffee products?
SELECT t3.city_name,count(distinct t1.customer_id) as count_of_customers
FROM sales t1
JOIN monco_customers t2
ON t1.customer_id = t2.customer_id
JOIN city t3
ON t2.city_id = t3.city_id
JOIN products t4
ON t1.product_id = t4.product_id
WHERE t4.product_name LIKE '%Coffee%'
group by t3.city_name;

#8. Average Sale vs Rent
## Find each city and their average sale per customer and avg rent per customer.
SELECT city_name,
ROUND(AVG(customer_sales), 2) AS avg_sales_per_customer,
ROUND(AVG(estimated_rent), 0) AS avg_rent_per_customer
FROM (SELECT t2.customer_id,
t1.city_name, t1.estimated_rent,
SUM(t3.total) AS customer_sales FROM city t1
JOIN monco_customers t2
ON t1.city_id = t2.city_id
JOIN sales t3
ON t2.customer_id = t3.customer_id
GROUP BY t2.customer_id, t1.city_name,t1.estimated_rent) AS customer_sales_data
GROUP BY city_name;

#9. Monthly Sales Growth
## Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
WITH monthly_sales AS
(
    SELECT
        DATE_FORMAT(sale_date, '%Y-%m') AS period,
        SUM(total) AS total_sales
    FROM sales
    GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
),
growth AS
(
    SELECT
        period,
        total_sales,
        LAG(total_sales) OVER (ORDER BY period) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    period,
    total_sales,
    previous_month_sales,
    ROUND(
        ((total_sales - previous_month_sales) / previous_month_sales) * 100,
        2
    ) AS growth_percentage
FROM growth;

#10. Market Potential Analysis
## Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer.
select t1.city_name,
sum(t3.total) as total_sales,
max(t1.estimated_rent) as total_rent,
count(distinct t2.customer_id) as total_customers,
round(t1.population * 0.25) as estimated_coffee_drinkers from city t1
join monco_customers t2
on t1.city_id = t2.city_id
join sales t3
on t2.customer_id = t3.customer_id
GROUP BY t1.city_name,t1.population,t1.estimated_rent
ORDER BY total_sales DESC
LIMIT 3;
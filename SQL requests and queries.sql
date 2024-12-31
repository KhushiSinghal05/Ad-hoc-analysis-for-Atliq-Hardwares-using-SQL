/* 10 Requests:

-------------------------------------------------------------------------------------------------------------
1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.

2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg

3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count

4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference

5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost

6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage

7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount

8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity

9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage

10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
codebasics.io
product
total_sold_quantity
rank_order*/

-------------------------------------------------------------------------------------------------------------

-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT DISTINCT
    market
FROM
    dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC';


/*2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg*/

with cte as(SELECT 
    COUNT(DISTINCT (CASE
            WHEN fs.fiscal_year = 2020 THEN p.product_code
        END)) AS unique_products_2020,
    COUNT(DISTINCT (CASE
            WHEN fs.fiscal_year = 2021 THEN p.product_code
        END)) AS unique_products_2021 FROM
    dim_product p
        JOIN
    fact_sales_monthly fs ON p.product_code = fs.product_code)
        select *,
    ((unique_products_2021 - unique_products_2020)*100/unique_products_2020)  AS percent_change from cte;


/*3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count*/

SELECT 
    segment, COUNT(DISTINCT (product_code)) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;


/*4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference*/

WITH product_count
     AS (SELECT p.segment,
                Count(DISTINCT( CASE
                                  WHEN fiscal_year = "2020" THEN p.product_code
                                END )) AS product_count_2020,
                Count(DISTINCT( CASE
                                  WHEN fiscal_year = "2021" THEN p.product_code
                                END )) AS product_count_2021
         FROM fact_sales_monthly s
                JOIN dim_product p
                  ON s.product_code = p.product_code
         GROUP BY p.segment)
SELECT *,
       product_count_2021 - product_count_2020 AS difference
FROM product_count
ORDER BY difference DESC; 


/*5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost*/

WITH cte
     AS (SELECT f.product_code,
                p.product,
                manufacturing_cost
         FROM   dim_product p
                JOIN fact_manufacturing_cost f
                  ON p.product_code = f.product_code)
SELECT *
FROM cte
WHERE  manufacturing_cost = (SELECT Max(manufacturing_cost) FROM cte)
        OR manufacturing_cost = (SELECT Min(manufacturing_cost) FROM cte); 


/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage*/

SELECT 
    pd.customer_code,
    customer,
    CONCAT(ROUND(AVG(pre_invoice_discount_pct) * 100, 2),
            '%') AS average_discount_percentage
FROM
    dim_customer c
        JOIN
    fact_pre_invoice_deductions pd ON c.customer_code = pd.customer_code
WHERE
    fiscal_year = 2021 AND market = 'India'
GROUP BY pd.customer_code , customer
ORDER BY AVG(pre_invoice_discount_pct) DESC
LIMIT 5;


/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount*/

        SELECT 
    MONTHNAME(s.date) AS Month,
    s.fiscal_year AS Year,
    SUM(sold_quantity * gross_price) AS Gross_sales
FROM
    fact_sales_monthly s
        JOIN
    fact_gross_price g ON s.product_code = g.product_code
        JOIN
    dim_customer c ON s.customer_code = c.customer_code
WHERE
    customer = 'AtliQ Exclusive'
GROUP BY month , year
ORDER BY year ASC;
         

/* 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity*/

select (case when extract(month from date) in(9,10,11) then 'Q1'
			when extract(month from date) in(12,1,2) then 'Q2'
			when extract(month from date) in(3,4,5) then 'Q3'
			when extract(month from date) in (6,7,8) then 'Q4'end) as Q ,
            sum(sold_quantity) as total_sold_quantity
            from fact_sales_monthly
            where fiscal_year=2020 
            group by Q
            order by total_sold_quantity desc;


/*9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage*/

SELECT 
    c.channel,
    SUM(sold_quantity * gross_price) AS gross_sales_mln
FROM
    dim_customer c
        JOIN
    fact_sales_monthly fs ON c.customer_code = fs.customer_code
        JOIN
    fact_gross_price g ON fs.fiscal_year = g.fiscal_year
WHERE
    fs.fiscal_year = 2021
GROUP BY 1
ORDER BY 2 DESC;


/*10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
codebasics.io
product
total_sold_quantity
rank_order*/

WITH cte
     AS (SELECT c.channel,
                Round(Sum(sold_quantity * gross_price), 2) AS gross_Sales_mln
         FROM   dim_customer c
                JOIN fact_sales_monthly fs
                  ON c.customer_code = fs.customer_code
                JOIN fact_gross_price g
                  ON fs.product_code = g.product_code
         WHERE  fs.fiscal_year = 2021
         GROUP  BY 1
         ORDER  BY 2 DESC)
SELECT *,
       Concat(Round(gross_sales_mln * 100 / (SELECT Sum(gross_sales_mln) FROM cte), 2), "%") AS percentage
FROM   cte
GROUP  BY channel; 

















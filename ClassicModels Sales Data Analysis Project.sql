/*
ClassicModels Sales Data Analysis

Skills used: Joins, Subqueries, Aggregate Functions

*/

                    -- Determining the Average order amount for EACH country --

-- Calculate the AVERAGE order amount for EACH country
-- For the average order amount for each country we need customer details to see which country they come from 
-- then join order and order details table to get the value of each order
-- amount = priceEach*quantity

SELECT country, COUNT(country) AS num_orders,
				SUM(priceEach*quantityOrdered) AS total_order_amount,
				avg(priceEach*quantityOrdered) AS ave_order_amount
FROM customers cus
INNER JOIN orders o                            -- we only want to see customers who made an order we dont want to include those that did not
ON cus.customerNumber = o.customerNumber
INNER JOIN orderdetails od
ON o.orderNumber = od.orderNumber              -- duplicates due to a customer making a lot of orders 
GROUP BY country
ORDER BY ave_order_amount DESC;


-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

                    -- Determining the Sales Value per Product Line --

-- Calculate the TOTAL sales amount for EACH product line

SELECT pl.productLine, SUM(priceEach*quantityOrdered) AS total_sales_for_each_productLine  
FROM orderdetails od
INNER JOIN products prod      
ON od.productCode = prod.productCode
INNER JOIN productlines pl
ON prod.productLine = pl.productLine
GROUP BY pl.productLine
ORDER BY total_sales_for_each_productLine DESC;

-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

                    -- Determining the Top 10 Products by Sales --

-- List the top 10 best- selling products based on total quantity sold

SELECT od.productCode, productName, SUM(quantityOrdered) AS quantity_sold
FROM orderdetails od
INNER JOIN products prod 
ON od.productCode = prod.productCode
GROUP BY od.productCode, productName
ORDER BY quantity_sold DESC
LIMIT 10;

-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

                    -- Sales Representative Performance -- 

-- Evaluate the sales performance of each sales representative

SELECT em.firstName,em.lastName, SUM(quantityOrdered*priceEach) AS total_order_value
FROM customers cus
INNER JOIN employees em
ON cus.salesRepEmployeeNumber = em.employeeNumber AND em.jobTitle = 'Sales Rep'
LEFT JOIN orders ord 
ON cus.customerNumber = ord.customerNumber
LEFT JOIN orderdetails od 
ON ord.orderNumber = od.orderNumber
GROUP BY em.firstName,em.lastName
ORDER BY total_order_value DESC;

-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

                    -- Average Number of Orders per Customer --

-- Calculate the AVERAGE number of orders placed  by each customer 

SELECT COUNT(o.orderNumber)/COUNT(DISTINCT cus.customerNumber) AS avg_number_of_orders_per_customer
FROM customers cus
LEFT JOIN orders o                                   -- we only want to see customers who made an order we dont want to include those that did not
ON cus.customerNumber = o.customerNumber;

-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 

                    -- Percent of Orders Shipped on Time --

-- Calculate the percentage of orders that were shipped on time

SELECT *,
CASE WHEN 
	shippedDate <= requiredDate THEN 'yes' 
	ELSE 'no' 
	END AS on_time
FROM orders;

SELECT SUM(CASE WHEN shippedDate <= requiredDate THEN 1 ELSE 0 END) / COUNT(orderNumber)*100 AS percent_on_time
FROM orders;
-- 1 is True and 0 is False
-- 95.3988

-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

                    -- NET PROFIT per PRODUCT --

-- Calculate the profit margin for each product by subtracting the cost of goods sold(COGS) from the sales revenue

SELECT productName,SUM((priceEach*quantityOrdered) - (buyPrice*quantityOrdered)) AS net_profit
FROM products prod
INNER JOIN orderdetails od
ON prod.productCode = od.productCode
GROUP BY productName;

-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

                    -- Segment Customers by Value --
					
-- Segment customers based on their total purchase amount
-- Meaning group customers into high medium and low value

-- 1. Find out each customers total purchase amount (the subQ)
SELECT *, 
CASE WHEN total_purchase_amount > 100000 THEN 'High Value'
	 WHEN total_purchase_amount BETWEEN 50000 AND 100000 THEN 'Medium Value'
     WHEN total_purchase_amount < 50000 THEN 'Low Value'
     ELSE 'Other'
     END AS customer_segment
FROM
(SELECT customerNumber, SUM(priceEach*quantityOrdered) AS total_purchase_amount 
FROM orders o
INNER JOIN orderdetails od
ON o.orderNumber = od.orderNumber
GROUP BY customerNumber)t1;

-- in addition we can join the above to customers to see what kind of customer each are
SELECT c.*, t2.customer_segment
FROM customers c
LEFT JOIN -- the nested subQ in order to bring the customer segment
(SELECT *, 
CASE WHEN total_purchase_amount > 100000 THEN 'High Value'
	 WHEN total_purchase_amount BETWEEN 50000 AND 100000 THEN 'Medium Value'
     WHEN total_purchase_amount < 50000 THEN 'Low Value'
     ELSE 'Other'
     END AS customer_segment
FROM
(SELECT customerNumber, SUM(priceEach*quantityOrdered) AS total_purchase_amount 
FROM orders o
INNER JOIN orderdetails od
ON o.orderNumber = od.orderNumber
GROUP BY customerNumber)t1
)t2
ON c.customerNumber = t2.customerNumber;
-- included customers who did not make a purchase

-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
 
                    -- Identify Cross Selling Opportunities --

-- Identify frequently co-purchased products to understand cross-selling opportunities
-- finding products that are purchased together
SELECT od.productCode, prod.productName, od2.productCode, prod2.productName, COUNT(*) AS purchased_together
FROM orderdetails od 
INNER JOIN orderdetails od2
ON od.orderNumber = od2.orderNumber AND od.productCode <> od2.productCode
INNER JOIN products prod 
ON od.productCode = prod.productCode 
INNER JOIN products prod2
ON od2.productCode = prod2.productCode 
GROUP BY od.productCode, prod.productName, od2.productCode, prod2.productName
ORDER BY purchased_together DESC;

-- ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

                    -- THE END --











-- Retrieving Data From Multiple Tables

-- so far we have selected column from a single table 
-- in the real world application we need to select clumn form multiple tables

-- Let's take a look at the orders table
-- in orders table we use customer_id to refer to a customer 
-- 		1) reduntant 2) we need to change multiple records in orders table

-- we would like to retrive data from orders table but insted of only showing customer_id, 
-- we would like to see customer's frist name and last name
-- What should we do:
-- combine columns in orders table with columns in the customers table

SELECT *
FROM orders
-- on what basis we want to join these tables?
-- after ON we write the condition to join these tables
INNER JOIN customers ON orders.customer_id = customers.customer_id;

-- as you can see, after all the columns from orders table we see all the columns from customers table

-- let's simplify the result!
SELECT order_id, first_name, last_name
FROM orders
INNER JOIN customers ON orders.customer_id = customers.customer_id;

-- customer_id is used in both tables! It is ambegious and you need to clarify it!
SELECT customer_id, first_name, last_name
FROM orders
INNER JOIN customers ON orders.customer_id = customers.customer_id;

SELECT orders.customer_id, first_name, last_name
FROM orders
INNER JOIN customers ON orders.customer_id = customers.customer_id;


SELECT o.customer_id, first_name, last_name
FROM orders AS o
INNER JOIN customers AS c 
	  ON o.customer_id = c.customer_id;


-- join order_items table with product 
SELECT *
FROM order_items AS oi
JOIN products AS p 
	ON oi.product_id = p.product_id;
    
SELECT oi.order_id, oi.product_id, p.name
FROM order_items AS oi
JOIN products AS p 
	ON oi.product_id = p.product_id;


-- --------------------------------------------------------------
-- How to combine tables accross multiple databases
-- we have another products table in sql_inventory db

SELECT oi.order_id, oi.product_id, p.name
FROM order_items AS oi
JOIN sql_inventory.products AS p 
	ON oi.product_id = p.product_id;
    

USE sql_inventory;
SELECT oi.order_id, oi.product_id, p.name
FROM sql_store.order_items AS oi
JOIN products AS p 
	ON oi.product_id = p.product_id;

-- --------------------------------------------------------------
-- self join: join a table with itself!
-- let's take a look at data in employee table in sql_hr db

USE sql_hr;
SELECT *
FROM employees AS e
JOIN employees AS m 
	ON e.reports_to = m.employee_id;

SELECT e.employee_id,e.last_name AS 'Employee',m.last_name AS 'Manager'
FROM employees AS e
JOIN employees AS m 
	ON e.reports_to = m.employee_id;
    
-- joining multiple tables
-- in sql_store db > orders table 
-- we can join it with customers table to get info about each customer
-- also we can join it with order_statuses table to get info about status of each order 

USE sql_store;
SELECT *
FROM orders AS o
JOIN customers AS c
	ON o.customer_id = c.customer_id
JOIN order_statuses AS os
	ON os.order_status_id = o.status;
    


SELECT o.order_id,
	o.order_date,
        c.first_name,
        c.last_name,
        os.name AS 'status' 
FROM orders AS o
JOIN customers AS c
	ON o.customer_id = c.customer_id
JOIN order_statuses AS os
	ON os.order_status_id = o.status;
    

-- in sql_invoicing db > payment table

USE sql_invoicing;
SELECT *
FROM payments AS p
JOIN clients AS c
	ON p.client_id = c.client_id
JOIN payment_methods AS pm
	ON pm.payment_method_id = p.payment_method;
    
SELECT 
    p.payment_id,
    c.name,
    p.amount,
    pm.name AS 'payment_method'
FROM payments AS p
JOIN clients AS c
	ON p.client_id = c.client_id
JOIN payment_methods AS pm
	ON pm.payment_method_id = p.payment_method;

-- compound join condition
-- look at the order_itmes table
-- you cannot uniqly identify records only based on order_id because there are douplicated values
-- this table has a composite primary key

-- we have the same situations in order_item_notes table 

USE sql_store;
SELECT *
FROM order_items AS oi
JOIN order_item_notes AS oin
	ON oi.order_id = oin.order_id
    AND oi.product_id = oin.product_id;
    
-- implicity join syntax
USE sql_store;
SELECT *
FROM orders AS o
JOIN customers AS c
	ON o.customer_id = c.customer_id;
    
USE sql_store;
SELECT *
FROM orders AS o , customers AS c
WHERE o.customer_id = c.customer_id;

-- if you forget to use WHERE you will get a cross join
-- every record in orders table will be joined with every record in customer table
-- it is better to use the explicit join syntax


-- outer joins
    
USE sql_store;
SELECT *
FROM customers AS c
JOIN orders AS o
	ON c.customer_id = o.customer_id;
    
-- for clarity let's pick some columns
USE sql_store;
SELECT 
    c.customer_id,
    c.first_name,
    o.order_id
FROM customers AS c
JOIN orders AS o
	ON c.customer_id = o.customer_id;
    
-- there is somthing is missing! we only see customers who have an order in our system!
-- if you look at the customer table you will see we have other customers

-- what happens if we want to see all customers whether they have an order or not
-- for that we use outer join

-- we have two types of outer joins: LEFT JOIN or RIGHT JOIN

-- LEFT JOIN: returns all customers wheather they have an order or not (the condition we set is true or not!)
USE sql_store;
SELECT 
    c.customer_id,
    c.first_name,
    o.order_id
FROM customers AS c
LEFT JOIN orders AS o
	ON c.customer_id = o.customer_id;

-- outer joins between multiple tables
-- if you look at the orders table you can see shipper_id 
-- let's join the orders table with the shippers table 

USE sql_store;
SELECT 
    c.customer_id,
    c.first_name,
    o.order_id
FROM customers AS c
LEFT JOIN orders AS o
	ON c.customer_id = o.customer_id
JOIN shippers AS sh
	ON o.shipper_id = sh.shipper_id
ORDER BY customer_id;
    
-- again the same probelm: only ordres are displayed that has a shipper_id
USE sql_store;
SELECT 
    c.customer_id,
    c.first_name,
    o.order_id,
    sh.name AS 'Shipper'
FROM customers AS c
LEFT JOIN orders AS o
	ON c.customer_id = o.customer_id
LEFT JOIN shippers AS sh
	ON o.shipper_id = sh.shipper_id
ORDER BY customer_id;

-- with this we are getting all the customers wheather they have an order or not
-- for all orders we will get the shipper wheather they have a shipper or not

-- Do not use LEFT and RIGHT JOIN toghather in one script because things are getting complex!

-- produce the rsult like this:
SELECT
    o.order_id,
    o.order_date,
    c.first_name AS 'Customer',
    sh.name AS 'Shipper',
    os.name AS 'Status'
FROM orders AS o
JOIN customers AS c
	ON o.customer_id = c.customer_id
LEFT JOIN shippers AS sh
	ON o.shipper_id = sh.shipper_id
JOIN order_statuses AS os
	ON o.status = os.order_status_id;
    
-- USING clause
-- if the column name is exactly the same across the two tables that you are trying to join
-- then you can use USING clause

SELECT 
    c.customer_id,
    c.first_name,
    o.order_id,
    sh.name AS 'Shipper'
FROM customers AS c
LEFT JOIN orders AS o
	-- ON c.customer_id = o.customer_id;
    USING (customer_id)
LEFT JOIN shippers AS sh
	USING (shipper_id);

-- what happens if we have composite primary key?!
USE sql_store;
SELECT *
FROM order_items AS oi
LEFT JOIN order_item_notes AS oin
	-- ON oi.order_id = oin.order_id
    -- AND oi.product_id = oin.product_id;
    USING (order_id, product_id);

-- NATURAL joins: join the tables based on the common columns
-- we don't have control over it
-- we only let the db engine decide how to join the tables
-- that may produce unexpected resutl!
SELECT 
    c.customer_id,
    c.first_name,
    o.order_id
FROM customers AS c
NATURAL JOIN orders AS o;


-- with joins we can combine columns from multiple tables
-- UNION: allows us to combine rows from multiple tables

-- let's say we want to create a report that shows all records later than 2019 are still active
-- and all older records are archived

SELECT *
FROM orders
WHERE order_date >= '2019-01-01';

SELECT 
    order_id,
    order_date,
    'ACTIVE' AS status
FROM orders
WHERE order_date >= '2019-01-01';

SELECT 
    order_id,
    order_date,
    'ARCHIVED' AS status
FROM orders
WHERE order_date < '2019-01-01';

-- now with UNION we can combine all the rows
SELECT 
    order_id,
    order_date,
    'ACTIVE' AS status
FROM orders
WHERE order_date >= '2019-01-01'
UNION
SELECT 
    order_id,
    order_date,
    'ARCHIVED' AS status
FROM orders
WHERE order_date < '2019-01-01';

-- in this example both queries are against the same table 
-- but we can have queries against different tables
-- remember the number of columns each query returns must be equal!

-- Mostly we are going to revist subquaries (a select statment in another SQL statement)
-- Restore all databases to its orignal state: 
	-- open create-database file and execute it in your workbench

-- ****************************[Subqueries]**********************
-- in sql_store db: find all products that are more expensive than Lettuce (id = 3)
Use sql_store;
SELECT *
FROM products
WHERE unit_price > (
	SELECT unit_price
    FROM products
    WHERE product_id = 3
	);


-- ****************************[The IN Operator]**********************
-- writing subqueries using IN operator
-- in sql_store db: find the products that have never been ordered
-- 1) from order_items find all the products in this table 2) what products are not in this table

Use sql_store;
SELECT DISTINCT product_id
FROM order_items; 

-- now we can use this quary as a subquary inside another quary
SELECT *
FROM products
WHERE product_id NOT IN (
	SELECT DISTINCT product_id
	FROM order_items
	);
    
-- we can also write a subquary that returens a table!

-- ****************************[The IN Operator]**********************
-- in sql_store: Find the products that have never been ordered

USE sql_store;

SELECT * 
FROM products
WHERE product_id NOT IN(
	SELECT DISTINCT product_id /* these are the products with orders */
	FROM order_items
	);

-- ****************************[Subqueries vs Joins]******************
-- Rewrite the same code by using JOIN
USE sql_store;
SELECT *
FROM products
LEFT JOIN order_items USING (product_id)
WHERE order_id IS NULL;

-- Consider the performance and readability of your code
-- always write the quary that execute faster!
-- same execution time, go with the quary that is most readable!

-- ****************************[ALL]**********************
-- Select invoices larger than all invoices of client 3
-- 1) get all the invoices of client 3

USE sql_invoicing;

SELECT *
FROM invoices
WHERE client_id = 3;

-- 2) find the largest invoice of the client 3
SELECT MAX(invoice_total)
FROM invoices
WHERE client_id = 3;

-- 3) use the previous quary as a subquary
SELECT *
FROM invoices
WHERE invoice_total > (
	SELECT MAX(invoice_total)
	FROM invoices
	WHERE client_id = 3
);

-- But there is another way to solve this problem using ALL keyword!
-- we use ALL when the subquary returns a list rather than a single value
SELECT *
FROM invoices
WHERE invoice_total > ALL (
	SELECT invoice_total
	FROM invoices
	WHERE client_id = 3
);

-- ****************************[ANY or SOME]**********************
-- First Let's run the previous quary with SOME and see the differences

USE sql_invoicing;
SELECT *
FROM invoices
WHERE invoice_total > SOME (
	SELECT invoice_total
	FROM invoices
	WHERE client_id = 3
);

-- compare the amount in invoices!

-- Now consider this example: Select clients with at least two invoices
-- First, the count of invoices for each client
SELECT client_id, count(*) /* count of everything*/
FROM invoices
GROUP BY client_id;

-- We are intersted in the client with at least two invoices
-- We need to do filtering after GROUP BY using HAVING
SELECT client_id, count(*)
FROM invoices
GROUP BY client_id
HAVING count(*) >= 2; /* applying filtering after GROUP By */

-- Now we need to select client with these ids
SELECT *
FROM clients
WHERE client_id IN (
	SELECT client_id
	FROM invoices
	GROUP BY client_id
	HAVING count(*) >= 2
    );

-- But there is another way to write this quary!
-- just replace "IN" with "= ANY"

SELECT *
FROM clients
WHERE client_id = ANY (
	SELECT client_id
	FROM invoices
	GROUP BY client_id
	HAVING count(*) >= 2
    );
    
-- ****************************[Correlated Subqueries]**********************
-- Sometimes the subquary has a correlation with the outer quary: we use a reference to the outter quary inside the subquary

-- From sql_hr, select employees whose salary is above the average in their office
-- Let's look at employees table: we have salary and office_id in which they are located!
-- For each office we need to calcuate avg salary, then return employees with more than avg

-- Sudo code would be:
-- for each employee
-- 	calculate the avg salary for employee.office
-- 	return the employee if salary > avg

-- Now we should convert this to quary!

-- in the first subquary: calculate the avg salary for employee.office
SELECT *
FROM employees e
WHERE salary > (
	SELECT AVG(salary)
    FROM employees
    WHERE office_id = e.office_id
	);
-- it goes to the employees table, for each employee it execute the subquary and it calculate avg salary for all employee in the same office
-- Note how did we get the employee in the same office!
-- then it moves to the second employee and calc avg salary for all employee in the same office
-- this is what we called a corrolated subquary: because in the sub quary we have a correlation with the outer quary

-- Differences between correlated subquaries and uncorrelated subquaries:
-- In uncorrelated subquaries: the subquary is only executed once!
-- But in correlated subquaries: the subquary is executed for each row in the main quary 

-- For these reasons, correlated subquaries can be slow!

-- ****************************[The EXISTS Operator]**********************
-- Select clients that have an invoice

-- We have two ways to solve this problem: IN and JOIN
-- First, what are the client that have an invoice
SELECT DISTINCT client_id
FROM invoices;

-- Then select only thoese client that are in this list
SELECT *
FROM clients
WHERE client_id IN (
	SELECT DISTINCT client_id
	FROM invoices
	);

-- If we use INNER JOIN between clients and invoices we will get only the clients that have an invoice
-- we can also use EXIST operator, but this time we are going to have a correlation

SELECT *
FROM clients c
WHERE EXISTS (
	SELECT client_id
	FROM invoices
	WHERE client_id = c.client_id
);
-- for every client we run the subquary and only check if there is a record in the invoices table that matches the condition in WHERE
-- What is the benefit of using this approach over the previous one?
-- The approach with uncorrelated subquary might return a very large list of items that might have a negative impact on the performance
-- but using the EXISTS, the ineer quary doesn't return the result set to the outter quary.
-- it only returns an indication wheather the condition is met or not!


-- *********************************************************************
-- *********************************************************************
-- Let's work with some of the most useful built-in mysql functions for working with numeric, datetime and string values
-- ****************************[Numeric Functions]**********************
SELECT ROUND(5.345);
-- to specify the precision for rounding:
-- with two digit after the decimal point
SELECT ROUND(5.345, 2);

-- smallest int that is greater or equal to this number
SELECT CEILING(5.345);

-- largest int that is greater or equal to this number
SELECT FLOOR(5.345);

-- calc absolute value of the number
SELECT ABS(-5.345);

-- generating random floiting point number between 0..1
SELECT RAND();

-- google mysql numeric funcitons

-- ****************************[String Functions]**********************
-- to get the number of char in a string
SELECT LENGTH('sky');

SELECT UPPER('sky');

SELECT LOWER('Sky');

-- removing unnecessary spaces, usful for data entered by a user
SELECT LTRIM('    Sky');
SELECT RTRIM('Sky      ');
SELECT TRIM('        Sky      ');

-- get the two char from left
SELECT LEFT('Sky',2);

-- get the two char from right
SELECT RIGHT('Sky',2);

SELECT SUBSTRING('SkyIsBlue',4,6);
SELECT SUBSTRING('SkyIsBlue',4);

-- returns the first occurance of a char or substring in a string
SELECT LOCATE('Is','SkyIsBlue');

-- replace substring with another substring in string
SELECT REPLACE('SkyIsBlue','Blue', 'Gray');

SELECT CONCAT('first_name', ' ' ,'last_name');

-- ****************************[Date Functions in MySQL]**********************
SELECT NOW(), CURDATE(), CURTIME();

-- extracting special component from NOW, all these functions return int values
SELECT YEAR(NOW()), MONTH(NOW()), DAY(NOW());

SELECT MONTHNAME(NOW()), DAYNAME(NOW());

-- let's get all the orders place in the current year:
SELECT *
FROM orders
WHERE YEAR(order_date) = YEAR(NOW());

-- ****************************[IF Function]**********************
-- suppose you want to test a condition and return different values depending on if the condition is ture or not
-- in the orders table: let's say we want to classify orders that generated in the current year as active and others as archived
-- IF(expression, first [expression is evaluated true], second [expression is evaluated false])

USE sql_store;
SELECT
	order_id, 
    order_date,
    IF(YEAR(order_date) = YEAR(NOW()), 
    'Active', 
    'Archived') AS category
FROM orders;

-- ****************************[The CASE Operator]**********************
-- what if we have multiple cases to test?
-- if function only allows single test expression
USE sql_store;
SELECT 
	order_id,
    CASE
		WHEN YEAR(order_date) = YEAR(NOW()) THEN 'Active'
        WHEN YEAR(order_date) = YEAR(NOW()) - 1 THEN 'Last Year'
        WHEN YEAR(order_date) < YEAR(NOW()) - 1 THEN 'Archived'
        ELSE 'Future'
	END AS category
FROM orders;

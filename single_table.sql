-- ------------------------------------------------
-- [SELECT Statment]
-- ------------------------------------------------

-- First select a database
-- The query that we will write will be executed against this database

USE sql_store;


SELECT customer_id
FROM customers;

-- it has two clauses: SELECT, FROM
SELECT customer_id
FROM customers
WHERE customer_id = 1;

SELECT *
FROM customers
-- WHERE customer_id = 1
ORDER BY first_name;

-- these clauses are optional 
-- remember order of these clauses matter! always use SELECT first and then FROM, ...

SELECT * FROM customers WHERE customer_id = 1 ORDER BY first_name;


-- ------------------------------------------------
-- [SELECT Statment in more details]
-- ------------------------------------------------

-- asking for all columns puts a lot of persure on the DB server

SELECT first_name, last_name
FROM customers
ORDER BY first_name;

-- if you change the order it will afect the result

SELECT last_name, first_name
FROM customers
ORDER BY first_name;

-- let's get the point for each customer as well
SELECT last_name, first_name, points
FROM customers
ORDER BY first_name;

-- let's say we want to use these points and calculate the amount of discount you wan to give to each customer.
-- you can do arithmatic operation
SELECT last_name, first_name, points + 10
FROM customers
ORDER BY first_name;

SELECT last_name, 
	   first_name, 
       (points + 10) * 100
FROM customers
ORDER BY first_name;

-- if there is any douplications, you can use DISTINCT keyword to remove douplications
SELECT state
FROM customers;

SELECT DISTINCT state
FROM customers;


-- give a proper name to this column as an alias
SELECT last_name, 
	   first_name, 
       (points + 10) * 100 AS discount_factor
FROM customers
ORDER BY first_name;

-- [?]
-- return all the products
 -- name
 -- unit price
 -- new price (unit_price*1.1) 10% more expensive
 
 SELECT name, unit_price, unit_price*1.1 AS new_price FROM products;



-- ------------------------------------------------
-- [WHERE CLause]
-- ------------------------------------------------
-- we use it to filter out data
-- get the customers with points greater than 3000

SELECT * 
FROM Customers
WHERE points > 3000;

-- when we execute this query, the query execution engine in MYSQL is going to 
-- iterate over all customers in the table. for each customer is going to evaluate this condition

-- > >= < <= = != or <>

SELECT * 
FROM Customers
WHERE state = 'VA';

SELECT * 
FROM Customers
WHERE state <> 'VA';

SELECT * 
FROM Customers
WHERE birth_date > '1990-01-01';

-- get all the order placed in 2018
SELECT * 
FROM Orders
WHERE order_date >= '2018-01-01' AND order_date < '2019-01-01';

-- ------------------------------------------------
-- [AND OR NOT operator]
-- ------------------------------------------------
SELECT * 
FROM Customers
WHERE birth_date > '1990-01-01' AND points > 2000;

SELECT * 
FROM Customers
WHERE birth_date > '1990-01-01' OR points > 2000;

SELECT * 
FROM Customers
WHERE birth_date > '1990-01-01' OR points > 2000 AND state = 'VA';

-- (higher precedence) order of processing is: NOT AND, OR, 
-- print(True or False and False)     # and has precedence
-- print((True or False) and False)   # parentheses change precedence
-- print(not False or True)        # not has precedence
-- print(not (False or True))      # parentheses change precedence
-- True, False, True, False

SELECT * 
FROM Customers
WHERE NOT (birth_date > '1990-01-01' OR points > 2000);

-- from the order_items table, get the items
-- for item id = 6
-- where the total price is greater than 30
SELECT * 
FROM order_items
WHERE order_id = 6 AND unit_price * quantity > 30;

-- ------------------------------------------------
-- [IN operator]
-- ------------------------------------------------
SELECT * 
FROM Customers
WHERE state = 'VA' OR state = 'GA' OR state = 'FL';

SELECT * 
FROM Customers
WHERE state IN ('VA' , 'GA' , 'FL');


SELECT * 
FROM Customers
WHERE state NOT IN ('VA' , 'GA' , 'FL');

-- ------------------------------------------------
-- [BETWEEN operator]
-- ------------------------------------------------
SELECT * 
FROM Customers
WHERE points >= 1000 AND points <= 3000;

SELECT * 
FROM Customers
WHERE points BETWEEN 1000 AND 3000;

-- this range is inclusive

-- ------------------------------------------------
-- [LIKE operator]
-- ------------------------------------------------

-- retrive records to match the specific string pattern
-- customers whose lastname start with 'b'
SELECT * 
FROM Customers
WHERE last_name LIKE 'b%';

SELECT * 
FROM Customers
WHERE last_name LIKE 'brush%';

SELECT * 
FROM Customers
WHERE last_name LIKE '%b%';

SELECT * 
FROM Customers
WHERE last_name LIKE '_y';

SELECT * 
FROM Customers
WHERE last_name LIKE '_____y';

SELECT * 
FROM Customers
WHERE last_name LIKE 'b____y';


-- ------------------------------------------------
-- [REGEXP operator]
-- ------------------------------------------------
-- allows us to search for more complex patterns
SELECT * 
FROM Customers
WHERE last_name REGEXP 'b'; -- %b%


-- we use the carrot sign to represent the begining of the string
SELECT * 
FROM Customers
WHERE last_name REGEXP '^b';

-- we use the $ sign to represent the begining of the string
SELECT * 
FROM Customers
WHERE last_name REGEXP 'd$';


-- pipe to represent multiple search patterns
SELECT * 
FROM Customers
WHERE last_name REGEXP 'field|mac|rose';

SELECT * 
FROM Customers
WHERE last_name REGEXP '^field|mac|rose';

SELECT * 
FROM Customers
WHERE last_name REGEXP '[gim]e';
-- ge, ie, me

SELECT * 
FROM Customers
WHERE last_name REGEXP '[a-h]e';


-- ------------------------------------------------
-- [IS NULL operator]
-- ------------------------------------------------
SELECT * 
FROM Customers;

SELECT * 
FROM Customers
WHERE phone IS NULL;

SELECT * 
FROM Customers
WHERE phone IS NOT NULL;

-- get the orders that are not shipped yet!
SELECT *
FROM orders
WHERE shipper_id IS NULL;

-- ------------------------------------------------
-- [ORDER BY cluase]
-- ------------------------------------------------

SELECT * 
FROM Customers
ORDER BY first_name;


SELECT * 
FROM Customers
ORDER BY first_name DESC;

SELECT * 
FROM Customers
ORDER BY state, first_name;

SELECT * 
FROM Customers
ORDER BY state DESC, first_name ASC;

-- ------------------------------------------------
-- [LIMIT cluase]
-- ------------------------------------------------
SELECT * 
FROM Customers
LIMIT 3;

SELECT * 
FROM Customers
LIMIT 6, 3; -- skip the first 6 records and then return 3

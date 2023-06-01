-- Queries can become very complex specially when you use JOIN or subquaries
-- VIEW will hlep you to deal with this complexity
-- You can save a quary in a view and this will greatly simplify our select statement
-- We can reuse thoes VIEWs again and you don't need to code them again!

-- ****************************[Creating Views]**********************
-- Let's write a quary to get the total sale for each client in sql_invoicing DB

USE sql_invoicing;
SELECT 
	c.client_id,
    c.name,
    SUM(invoice_total) AS total_sales
FROM clients c
JOIN invoices i USING (client_id)
GROUP BY client_id, name;

-- This is a very useful quary and in the future we might have a lot of other queries based on this queary
-- e.g., get the list of top clients or client with least sales

-- one example order the result in DESC order based on total_sale
USE sql_invoicing;
SELECT 
	c.client_id,
    c.name,
    SUM(invoice_total) AS total_sales
FROM clients c
JOIN invoices i USING (client_id)
GROUP BY client_id, name
ORDER BY total_sales DESC;

-- another example applying some filtering
USE sql_invoicing;
SELECT 
	c.client_id,
    c.name,
    SUM(invoice_total) AS total_sales
FROM clients c
JOIN invoices i USING (client_id)
GROUP BY client_id, name
HAVING total_sales > 500
ORDER BY total_sales DESC;


-- instead of writing this quary everytime and change it slightly for each quary 
-- we can save this in a VIEW and use the VIEW in many places

-- creat a VIEW
CREATE VIEW sales_by_client AS
SELECT 
	c.client_id,
    c.name,
    SUM(invoice_total) AS total_sales
FROM clients c
JOIN invoices i USING (client_id)
GROUP BY client_id, name;

-- Refresh the navigator and expand the VIEWS dir and see this view
SELECT * 
FROM sales_by_client
ORDER BY total_sales DESC;

SELECT * 
FROM sales_by_client
WHERE total_sales > 500
ORDER BY total_sales DESC;

SELECT * 
FROM sales_by_client
JOIN clients USING (client_id);

-- VIEWs are powerfull and greatly simplify our future queries
-- They behaves like a virtual table
-- NOTE: VIEWS DONT STORE DATA! our data only stored in tables!
-- it provides a view to underlying tables


-- ****************************[Altering or Dropping Views]**********************
-- once you create a view you may realize that your quary had a problem so you may want to go back and change the viwe
-- 1) DROP the viwe and recreate it

DROP VIEW sales_by_client;

-- 2) CREATE OR REPLACE, you don't need to drop the view first!
CREATE OR REPLACE VIEW sales_by_client AS
SELECT 
	c.client_id,
    c.name,
    SUM(invoice_total) AS total_sales
FROM clients c
JOIN invoices i USING (client_id)
GROUP BY client_id, name;

-- what if this quary window is gone and you don't have access to the quary behind this view
-- save views in sql file and put in GIT
-- git init, git add ., git commit -m "init commit" 

-- 3) open view in edite mode, add this "ORDER BY total_sales DESC;" click apply btn
-- this is not the best way to change VIEWs
-- the best way is to put your code under souce control


-- ****************************[Updatable Views]**********************
-- so far we have seen views in select statments but we can use views in insert, update and delete statments
-- bu only under certain conditions:
/* If the view doesn't have the following words:
-- DISTINCT
-- Aggregate Functions (MIN, MAX, SUM, etc.)
-- GROUP BY / HAVING
-- UNION
we consider it as an updateable view */

-- let's have a quick look at our invoices table: we have invoice_total and payment_total
-- but we don't have a column for balance
-- every time we work with balance we have to calculate it!
-- now we want to create a VIEW that include balance for each invoice

CREATE OR REPLACE VIEW invoices_with_balance AS
SELECT
	invoice_id,
    number,
    client_id,
    invoice_total,
    payment_total,
    
    invoice_total - payment_total AS balance,
    
    invoice_date,
    due_date,
    payment_date
FROM invoices
WHERE (invoice_total - payment_total) > 0;

-- This is a updateable view and we can use it to modify our data
DELETE FROM invoices_with_balance
WHERE invoice_id = 1;

-- we can also updata an invoice: let's push the due date for invoice # 2 to two days after

UPDATE invoices_with_balance
SET due_date = DATE_ADD(due_date, INTERVAL 2 DAY)
WHERE invoice_id = 2;


-- to recap: most of the time we update data through our tables
-- but there are times that you may not have direct access to a table 
-- for security reasons, so your only option is to modify data through a view


-- ****************************[THE WITH OPTION CHECK Clause]**********************
-- following the same exmaple, let's see what happens when we update the payment total for one of these invoices
-- for invoice_id 2: let's set its payment total to exact value as invoice total.
-- so balance is going to become 0!
-- what do you think will happen?

UPDATE invoices_with_balance
SET payment_total = invoice_total
WHERE invoice_id = 3; 

-- let's referesh the view and see what happens
-- invoice_id = 3 disappeared! this is a default behavoiour from views
-- when you update a record it might disappear!
-- but there are times that you want to prevent this
-- you don't want an update exclude the row from view!
-- for this you just need to add "WITH CHECK OPTION;"

CREATE OR REPLACE VIEW invoices_with_balance AS
SELECT
	invoice_id,
    number,
    client_id,
    invoice_total,
    payment_total,
    invoice_total - payment_total AS balance,
    invoice_date,
    due_date,
    payment_date
FROM invoices
WHERE (invoice_total - payment_total) > 0
WITH CHECK OPTION;

-- this option doesn't allow the view to be updated in case the update change 
-- would exclude the row afterwards;

-- ****************************[Other Benefits of Views]**********************
-- simplify quaries

--  Views can reduce the impact of changes to your database desing (?)
-- 		imaging you have 10 queries written on top of your invoices table
-- 		tomorrow you decised to make a change in this table, rename the table our one of its columns
-- 		what will happen to the queries, you have to fix all of thoes queries that reference the table!
-- 		in these situation you can simply use the view you have created earlier
-- 		in the view you can use the old names or if you moved one column to another tabel you can join the view with that table and bring it to the view and work with it in your old quaries
-- 		if your quearies are based on this view they will not be affected by the changes in the underlying table
-- 		VIEWS provide abstraction over our database table and that abstraction reduces the impact of changes

-- We can use views to restict access to the data in the underlying tables
-- 		for exampl, in th veiw you may use a WHERE cluse to filter the records or exclude some of the columns in the underlying table
-- 		and user might not be able to modify the value of the certain columns or rows
-- 		

-- ****************************************************
-- ****************************************************
-- *****************[Stored Procedures]****************
-- ****************************************************
-- ****************************[What are Stored Procedures]**********************
-- at this point you know how to write complex queries and simplfing them by wrtting them into views
-- and also you know how to insert, delete, and update data using sql statments
-- let's say you have an application with DB
-- where are you going to write this sql statments?
-- in your applicaiton code? NO, it make your app code messy and hard to maintain. 
-- 		also some programing languages requrires some compilation step, so you need to recompile and redeploy your app code if you want to update a sql code!

-- 	So you should store them in a DB where they blong! but where? inside a stored procedure or function!

-- Stored Procedure is a DB object that contains a block of SQL code

-- in our app code we simply call these procedures to get or save the data

-- stored procedures have other benefits: most DBMSs perform some optimisation to the code in stored procedures
-- so code in stored procedures can be executed faster
-- also Just like VIEWs they allow us to enforce data security
-- e.g., you can remove direct access to all the tables and allow various operations like insert, update etc to be perfomred only by your stored procedures
-- then we can decide how can exe what stored procedures and that will limite what the user can do with our data
-- e.g., you can prevent certain users from deleting our data in cetain tables



-- ****************************[Creating a Stored Procedure]**********************
-- It starts with the procedure name and its body
-- in real-word statmets have multiple lines.
-- we want to give all the satement as a singel unite, rather than individual statment separated using semicolon

-- CREATE PROCEDURE get_clients()
-- BEGIN
-- 	SELECT * FROM clients;
-- END

-- we want to change the default delimiter ; to something else

DELIMITER $$
CREATE PROCEDURE get_clients()
BEGIN
	SELECT * FROM clients;
END $$
DELIMITER ;

-- exe this and open up the navigator panel and check the stored procedures

CALL get_clients();

-- ****************************[Creating Procedures Using MySQLWorkbench]**********************
-- right click on the stored procedure row in navigator
-- get_payments --> SELECT * FROM payments;

-- ****************************[DROP stored procedure]**********************
-- DROP stored procedure is useful specially if you have made a mistake in creating the procedure
DROP PROCEDURE get_clients;

-- ok it is gone! but if you exe it one more time you will get an error!
-- to prevent the error we should use IF EXISTS

DROP PROCEDURE IF EXISTS get_clients;

-- just like views it is good practice to keep your procedures under git control
-- then you can monotore any chnages to that every time you work with it

-- so we usually create a stored producedure using this template:

DROP PROCEDURE IF EXISTS get_clients;
DELIMITER $$
CREATE PROCEDURE get_clients()
BEGIN
	SELECT * FROM clients;
END $$
DELIMITER ;

-- now you can save this in a file called get clients



-- ****************************[Parameters]**********************
-- How to add a Parameter to a stored procedure
-- we want the procedure to recieve a state and returns all clients on that state

DROP PROCEDURE IF EXISTS get_clients_by_state;
DELIMITER $$
CREATE PROCEDURE get_clients_by_state
(
	state CHAR(2) /* represents a string with two chars */
)
BEGIN
	SELECT * FROM clients c
    WHERE c.state = state;
END $$
DELIMITER ;

-- let's call this procedure
CALL get_clients_by_state("CA");

-- what if we don't supply a parameter?!

-- ****************************[Parameters with Default Value]**********************
-- How to assign value to a parameters as Default Value

-- back to our previous example, if the caller of that procedure doesn't specify a state
-- we want to reture clients in CA by default

DROP PROCEDURE IF EXISTS get_clients_by_state;
DELIMITER $$
CREATE PROCEDURE get_clients_by_state
(
	state CHAR(2) /* represents a string with two chars */
)
BEGIN
	
    IF state IS NULL THEN
		SET state = "CA";
	END IF;
    
	SELECT * FROM clients c
    WHERE c.state = state;
END $$
DELIMITER ;

CALL get_clients_by_state(NULL);

-- what if we want to return all clients if no state is provided for the procedure
DROP PROCEDURE IF EXISTS get_clients_by_state;
DELIMITER $$
CREATE PROCEDURE get_clients_by_state
(
	state CHAR(2) /* represents a string with two chars */
)
BEGIN
	
    IF state IS NULL THEN
		SELECT * FROM clients;
	ELSE
		SELECT * FROM clients c
		WHERE c.state = state;
	END IF;
    
END $$
DELIMITER ;

CALL get_clients_by_state(NULL);

-- more concise way of writing this code is suing IFNULL function
-- IFNULL(A,B), if A is null it retures B

DROP PROCEDURE IF EXISTS get_clients_by_state;
DELIMITER $$
CREATE PROCEDURE get_clients_by_state
(
	state CHAR(2) /* represents a string with two chars */
)
BEGIN
	
    IF state IS NULL THEN
		SELECT * FROM clients c
        WHERE c.state = IFNULL(state, c.state);
	END IF;
    
END $$
DELIMITER ;

CALL get_clients_by_state(NULL);

-- ****************************[Parameter Validation]**********************
-- so far you have only seen procedures that select data 
-- but we can use procedure to update, delete and insert data
-- let's write a procedure to updata an invoice
-- also do some parameter validation to make sure to ensure our procedure does not accidentaly store bad data

DROP PROCEDURE IF EXISTS make_payment;

DELIMITER $$

CREATE PROCEDURE make_payment
(
	invoice_id INT,
    payment_amount DECIMAL(9, 2), /* it represents number with decimal point, first argument represent the total number of digits, the number of digits after the decimal point */
    payment_date DATE
)
BEGIN
	UPDATE invoices i
    SET
		i.payment_total = payment_amount,
        i.payment_date = payment_date
	WHERE i.invoice_id = invoice_id;

END $$
DELIMITER ;

-- now if you call the procedure ...
call sql_invoicing.make_payment(1, 100, '2023-01-01');
-- let's back to the invoices table and verify the invoice updated properly

-- what if we set payment amount to -100 !
-- we shouldn't store invalid data!
-- we should validate arguments we pass to this stored procedure

-- to this end, before the upadata statement:
-- to find the error code: google sqlstate errors

-- IF payment_amount <= 0 THEN
-- 	SIGNAL SQLSTATE '22003' SET MESSAGE_TEXT = 'Invalid payment amount';
-- END IF;

DROP PROCEDURE IF EXISTS make_payment;

DELIMITER $$

CREATE PROCEDURE make_payment
(
	invoice_id INT,
    payment_amount DECIMAL(9, 2), /* it represents number with decimal point, first argument represent the total number of digits, the number of digits after the decimal point */
    payment_date DATE
)
BEGIN
	IF payment_amount <= 0 THEN
		SIGNAL SQLSTATE '22003' SET MESSAGE_TEXT = 'Invalid payment amount';
	END IF;
	
    UPDATE invoices i
    SET
		i.payment_total = payment_amount,
        i.payment_date = payment_date
	WHERE i.invoice_id = invoice_id;

END $$
DELIMITER ;


-- ****************************[Output Parameters]**********************
-- using parameters to return values to the calling program
-- let's write a procedure to get unpaid invoices for a client

DROP PROCEDURE IF EXISTS get_unpaid_invoices_for_client;

DELIMITER $$

CREATE PROCEDURE get_unpaid_invoices_for_client
(
	client_id INT
)
BEGIN
	SELECT COUNT(*), SUM(invoice_total)
    FROM invoices i
    WHERE i.client_id = client_id
		AND payment_total = 0;
END $$
DELIMITER ;

-- try client_id = 3
-- 2	286.08
-- we can also recieve this value through parameters:

-- first add these two parameters:
--     OUT invoices_count INT,
--     OUT invoices_total DECIMAL(9, 2)
-- by default these parameters are input parameters; when we
-- add OUT it represents output parameters;

-- now we need to make slight change in our select statment:
-- INTO invoices_count, invoices_total

DROP PROCEDURE IF EXISTS get_unpaid_invoices_for_client;

DELIMITER $$

CREATE PROCEDURE get_unpaid_invoices_for_client
(
	client_id INT,
	OUT invoices_count INT,
    OUT invoices_total DECIMAL(9, 2)
)
BEGIN
	SELECT COUNT(*), SUM(invoice_total)
    INTO invoices_count, invoices_total
    FROM invoices i
    WHERE i.client_id = client_id
		AND payment_total = 0;
END $$
DELIMITER ;

-- if you exe the procedure it will generate this for us:
set @invoices_count = 0;
set @invoices_total = 0;
call sql_invoicing.get_unpaid_invoices_for_client(3, @invoices_count, @invoices_total);
select @invoices_count, @invoices_total;

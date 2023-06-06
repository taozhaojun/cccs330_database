-- [Triggers and Events ]
-- ****************************[Triggers]**********************
-- A trigger is a block of sql code that automatically gets executed before or after an insert, update or delete statement
-- often we use trigger to enforce data consistancy
-- in sql_store DB, we can have multiple payments towards a given invoice 
-- in invoices table we have payment total that must be equat to sum of the all payments for this invoice
-- So whenever we insert a new record in the payments table, we should make sure that the payment_total column in the invoices table is updated
-- this is where we should use triggers!

DELIMITER $$
-- It shows this trigger is associated to this table and it is fired after we insert a record
CREATE TRIGGER payments_after_insert
	AFTER /*BEFORE*/ INSERT  ON payments
    FOR EACH ROW /* if we insert 5 rows it will be fired for each row, some DBMSs support table level triggered that only fired once */
BEGIN
/* body of the trigger */
END$$
DELIMITER ;


-- in the body we can write any code to make sure the consistancy, a raw sql or call a stored procedure
-- UPDATE invoices 
-- SET payment_total = payment_total + NEW.amount
-- WHERE invoice_id = NEW.invoice_id;

-- using NEW we can access to all column of the new record we are going to insert

-- before test our new trigger, in this trigger we can modify data in any tables except the table that this trigger is for "payments"
-- otherwise we will end up with an infinit loop!


DELIMITER $$
CREATE TRIGGER payments_after_insert
	AFTER INSERT  ON payments
    FOR EACH ROW 
BEGIN
	UPDATE invoices 
    SET payment_total = payment_total + NEW.amount
    WHERE invoice_id = NEW.invoice_id;
END $$
DELIMITER ;

-- let's insert a new payment, check payments table and invoices tables
INSERT INTO payments
VALUES (DEFAULT, 5, 3, '2023-01-01', 10, 1);


-- Create a trigger that gets fired when we
-- delete the payment with id = 9.
-- make sure to add the auditing script so that when a record is deleted a record is inserted into the payment_audit table

DELIMITER $$


CREATE TRIGGER payments_after_delete
	AFTER DELETE ON payments
    FOR EACH ROW
BEGIN
	UPDATE invoices 
    SET payment_total = payment_total - OLD.amount
    WHERE invoice_id = OLD.invoice_id;
END $$

DELIMITER ;

DELETE FROM payments
WHERE payment_id = 9;

-- ****************************[Viewing Triggers]**********************
-- How can we see the triggers that we have just created?
SHOW TRIGGERS;

-- we can also filter the result
-- suppose we only want to see triggers created for the payments table
SHOW TRIGGERS LIKE 'payments%';



-- ****************************[Dropping Triggers]**********************
-- just like stored procedures and functions
 DROP TRIGGER IF EXISTS payments_after_insert;

-- IF EXISTS is optional

-- as a best practice we should have drop and create in one script file
-- DROP TRIGGER IF EXISTS payments_after_insert;
-- CREATE TRIGGER payments_after_insert


-- ****************************[Using Triggers for Auditing]**********************
-- we have seen how to use triggers for data consistancy 
-- but we can use trigger for logging changes to the data and auditing
-- whenever someone insert or delete a record, we can log that somewhere
-- later we can come and see who made what changes and when

-- We have this sql script to create a new table for keeping track of the changes
USE sql_invoicing;

CREATE TABLE payments_audit
(
	client_id 	INT				NOT NULL,
    date		DATE			NOT NULL,
    amount		DECIMAL(9, 2)	NOT NULL,
    action_type	VARCHAR(50)		NOT NULL,
    action_date	DATETIME		NOT NULL
);

-- execute this and checkout tables in the sql_invoicing db
-- let's add some auditing scripts in the trigger's body:
-- INSERT INTO payments_audit
-- VALUES (NEW.client_id, NEW.date, NEW.amount, 'Insert', NOW());
-- now recreate the trigger with the new body

DELIMITER $$
DROP TRIGGER IF EXISTS payments_after_insert;
CREATE TRIGGER payments_after_insert
	AFTER INSERT  ON payments
    FOR EACH ROW 
BEGIN
	UPDATE invoices 
    SET payment_total = payment_total + NEW.amount
    WHERE invoice_id = NEW.invoice_id;
	
    INSERT INTO payments_audit
	VALUES (NEW.client_id, NEW.date, NEW.amount, 'Insert', NOW());
END $$
DELIMITER ;

-- NOTE: if you wanted to add this auditing scritp for the delete trigger,
-- you would have to get the OLD values, instead of NEW
-- INSERT INTO payments_audit
-- VALUES (OLD.client_id, OLD.date, OLD.amount, 'Delete', OLD());
-- remeber this and use it to solve the trigger assingment

-- now let's create a new payment and insert it into a the payments:

INSERT INTO payments
VALUES (DEFAULT, 5, 3, '2023-04-03', 10, 1);
DELETE FROM payments
WHERE payment_id = 10;

-- let's check the payment audit table
-- now we know at this date and time a new record was inserted into this table

-- in the real-world applicaiton you may want to log changes in many tables
-- in that case you shouldn't create a separate audit table for each table in your database
-- instead you need a general structure for logging changes that is dectated by the business rules of the db.


-- ****************************[EVENTS]**********************
-- what an event in database is?
-- an event is a task or a block of sql code that gets executed according to the schedule
-- it can executed once or on a reqular basis like everyday at 10am or once a month and so on!


-- with events we can automate database manitenace tasks such as deleting stale data or copying data from one table to another
-- or aggrigating data to generate reports 

-- first we need to turn on mysql event scheduler, that is basically a process runs in the background
-- and it constantly looks for events to execute

-- all mysql variables
SHOW VARIABLES;

--  but we are only looking for event scheduler variable 
SHOW VARIABLES LIKE 'event%';

-- at your organization it might be turned off to save system resources
SET GLOBAL event_scheduler = ON;

-- let's create an event to delete all old records in payments_audit table
-- We name the event like this: starting with yearly, monthly, daily, etc.

DELIMITER $$

CREATE EVENT yearly_delete_stale_audit_rows
ON SCHEDULE 
	-- AT '2023-05-01' -> this is when an event is done only once;
    EVERY 1 YEAR STARTS '2023-01-01' ENDS '2029-01-01'
DO BEGIN
	DELETE FROM payments_audit
    WHERE action_date < NOW() - INTERVAL 1 YEAR;
END $$

DELIMITER ;

-- instead of "NOW() - INTERVAL 1 YEAR;" you can use either:
-- DATEADD (NOW(), INTERVAL -1 YEAR)
-- DATESUB (NOW(), INTERVAL 1 YEAR)



-- ****************************[Viewing, Dropping and Altering Events]**********************
-- to show all events:
SHOW EVENTS;

-- to show only events that run yearly:
SHOW EVENTS LIKE 'yearly%';

-- to drop an event:
DROP EVENT IF EXISTS yearly_delete_stale_audit_rows;

-- we also have ALTER statement to make changes to an event
-- temproralty enable or disable an event
ALTER EVENT yearly_delete_stale_audit_rows DISABLE;
ALTER EVENT yearly_delete_stale_audit_rows ENABLE;

-- that conclude our discussion about events!
-- as you have seen we use events to automate db maintenance tasks!






-- ****************************[Transactions in MySQL]**********************
-- a transaction is a group of sql statments that represent a single unit of work
-- so all the statments should be completed successfully or transaction will fail
-- think of a banck transaction:
-- when you transfer 10$ from your account to your friend's account.
-- it should be taken out from your account and deposited to your friend's account
-- so we have two operations that togather represent a single unit of work
-- either two opeations will successefully completed or we need to roll back and revert the changes
-- a db transaction is exactly the same!

-- we use transactions in situations where we want to do multiple changes to db
-- and we want all these changes succeed or fail togather as a single unit

-- let's say we want to store an order with an iteam in db
-- what sql statments we need?
-- 		insert into orders ...
-- 		insert into order_items ...

-- what if the db server crashes at the time we try to ineset into order_items table
-- we end up with an incomplete order and our db will no be in a consistant sate
-- but we don't want that, that is why we use transactions

-- a transaction has a few property that you need to know:
-- Atomicity: trasactions are like atoms they are not breakable into smaller pieces, no matter how many statments it contains
-- 			  all of them are successfully completed or all changes will be rolled back
-- Consistancy: the database will always remain in a consistant state, so we won't endup with an other without an item
-- Isolation: all transactions are isolated and protected from eachother if they are try to modify the same data
-- 			  they cannot interfear with eachother
-- 			  what happens if multiple transactions are trying to update the same record or data
-- 			  the rows that are bing affected get locked so only one transaction at a time can update thoes rows
-- 			  other transactions have to wait untile that one is done!
-- Durability: once a transaction is committed, the changes made by the transaction are premanent
-- 			   so if you have a power failour or system crash, we are not going to lose the changes

-- we refere to these properties as ASID

-- now I am going to show you how to create a transaction:


-- ****************************[Creating Transactions]**********************
-- let's create a transaction to store an order with an item
-- beofore getting started let's restore our db to its initial status by running create db script

USE sql_store;

START TRANSACTION;

INSERT INTO orders (customer_id, order_date, status)
VALUES (1, '2023-04-04', 1);

INSERT INTO order_items
VALUES (LAST_INSERT_ID(), 1, 1, 1); /* LAST_INSERT_ID() this will return an id of the new inserted order */

COMMIT; -- when mysql sees this command it will write all the changes to the db, if one is failed it will automatically undo the prevous one and we say the transaction is rolled back!
-- instead of COMMIT you can use ROLLBACK; this is an option to return to the previous stage;

-- let's execute the transcation and check the orders and order_items table

-- now le't simoulate the senario where the second statment is failed
-- we run line by line and then before inster into order_items we disconnect the db

-- mysql wraps every single statment we write inside a transaction and then it will do the COMMIT if that statment did't return an error
-- this is controlled using a system variable called autocommit

SHOW VARIABLES LIKE 'autocommit%';

-- ****************************[Concurrency and Locking]**********************
-- so far we have been the only user of our db 
-- but in the realworld it is quite possible that two or more users may try to access the same db
-- this is concurrancy!
-- there will be a problem when one user try to change a data while the other user is retrive the data to do some calculation or other operations
-- now we will learn how mysql will handel concurency by default

-- so we are going to simulate two users trying to update the points for a given customer at the same time 
-- using mysql workbench open a new connection to our db


-- let's creat a transaction:
USE sql_store;
START TRANSACTION;

UPDATE customers
SET points = points + 10
WHERE customer_id = 1;

COMMIT;

-- don't execute it yet!
-- copy the code and paste it to our new session

-- before running the code let's check how many points customer_id = 1 has! 2273
-- now execute the scripts line by line up to commit
-- do this agian in the new session
-- see the spin is running 
-- that means the second transaction must wait until the first transaction either commited to rolled back
-- if you wait long, the opertion will be timed out!

-- now if you run COMMITs you will see that the points increases 20!

-- with the default locking behaviour in MYSQL, many concorency problems will be delt with automatically!
-- but there are special cases where the default behaviour is not sufficient
-- in those situations you can overwite the default behaviour



-- ****************************[Common Concurrency Problems]**********************
-- see the slides

-- ISOLATION LEVELS --
-- 1. READ UNCOMMITTED - the lowest isolation level with all concurrency problems;
-- 2. READ COMMITTED - here we don't have dirty reads, but do have unrepeatable or inconsistent reads.
-- 3. REPEATABLE READ - this is the DEFAULT isolation level in mysql, which solves most of the concurrency problems (not phantom reads);
-- 4. SERIALIZABLE - solves all concurrency problems, but has more locks, recourses which can hurt performances and reliability.


-- ****************************[Transaction Isolation Levels]**********************
-- to show the current transaction isolation level
SHOW VARIABLES LIKE 'transaction_isolation%';

-- to set the isolation level for the next transaction
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- to change it for all transaction in the current session you can:
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- to make it global for all trasaction in all sessions:
SET GLOBAL TRANSACTION ISOLATION LEVEL SERIALIZABLE;

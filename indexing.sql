-- [Indexing for High Performance]
-- ****************************[Introduction]**********************
-- in this session we are going to look at indexing for high performance
-- indexing are exterimly important in large dbs and high traffic website 
-- because they can improve the performance of our queries dramatically
-- we will learn how to creat them, and work with them to speedup our queries
-- this is an important topic that every developer and db admin must learn
-- before we get started, exe the script 
-- with this script we are going to populate our customer table with 1000 new records
-- so we can see the impact of indexes on our queries


-- ****************************[Creating Indexes]**********************
-- let's write a query to get the customers located in CA
USE sql_store;
SELECT customer_id FROM customers WHERE state = 'CA';

-- let me show you how mysql execute this query
-- prefix the command with EXPLAIN keyword

EXPLAIN SELECT customer_id FROM customers WHERE state = 'CA';

-- type = ALL tells us mysql need to do the full table scan
-- mysql need to read and scan every single record 
-- this can get very slow as the customer table grows largly

-- so we put an index on the state column to speedup this query
CREATE INDEX idx_state ON customers (state);

-- now execute this line again and see the differences
EXPLAIN SELECT customer_id FROM customers WHERE state = 'CA';



-- write a quiary to find customers with more than 1000 points 
-- then create index for the column points
-- examin the changes

EXPLAIN SELECT customer_id
FROM customers
WHERE points > 1000;


CREATE INDEX idx_points ON customers (points);

-- ****************************[Viewing Indexes]**********************
--
SHOW INDEXES IN customers;

-- whenever we add a pk to a table, mysql will automatically create an index 
-- collation represents how data are sorted in the index A accending, B decending
-- cardinality the number of unique values in the index 

-- but the numbers that it shows are not accurate 
-- to get more accurate values we should run 
ANALYZE TABLE customers;

SHOW INDEXES IN orders;
-- whenever we create a relationship btween two tables MSQL create an index on the fks so we can quickly join our tables.

-- also you can see the indexes in the navbar inside the index dir

-- ****************************[Prefix Indexes]**********************
-- you have learnt how to create a new index

-- if the column that you are going to create index on is an string column
-- like char, varchar, text, blob

-- our index may consumn a lot of space and it wont perform well
-- smaller indexes are better because they can fit in memory 
-- so when we index a string column, we don't want to include entier content as index
-- we just want to include a few first char and make our index smaller

-- suppose you want to create an index on the lastname column in the table
-- because last name is string we can include the numbr of charcter that we want to use to produce index
CREATE INDEX idx_lastname ON customers (last_name(20));

-- it is optional for char and varchar column but compolsory for text and blob columns
-- 20 is not a magic number 
-- to pick the best number we should look at the data
-- we want to include enought char to uniqly identify each customer

-- let's see how many uniqu vlaue we will have if we only include 1 char as index
SELECT 
	COUNT(DISTINCT LEFT(last_name, 1))
FROM customers;

-- the goal here is to maximize this value but at the same time we don't want to make index length too long
-- let's see what happens if we include 5 chars
SELECT 
	COUNT(DISTINCT LEFT(last_name, 1)),
        COUNT(DISTINCT LEFT(last_name, 5))
FROM customers;

-- now we get a great improvment (from 25 to 966)
-- let's see what happens if we include 10 chars
SELECT 
    COUNT(DISTINCT LEFT(last_name, 1)),
    COUNT(DISTINCT LEFT(last_name, 5)),
    COUNT(DISTINCT LEFT(last_name, 10))
FROM customers;

-- not a great improvment but we have doubled the length of the index!



-- ****************************[Full-text Indexes]**********************
-- we use these indexes to build a fast and flexible search engins in our applicaitons
-- download and execute create-db-blog script 
-- suppose we want to create a blog website and we want to give user the ability to search for blog posts
 
-- take a look at the post table
-- let's say a user want to search for 'react redux' on the blog
-- how can we find posts that are about react redux:

USE sql_blog;
SELECT * 
FROM posts
WHERE title LIKE '%react redux%' OR
	  body LIKE '%react redux%';

-- there are a few issues with this query:
-- 1) currently we don't have any index for these columns as your table grows large this query become slower
-- 2) it only returns posts that have exact these two words in the same sequence
-- it does not return posts that have react and redux in different order

-- this query is not really helpful in building a search engin
-- this is where we will use full indexes, they store entire content not just a prefix
-- they ignore any stop worlds like in, on, etc.
-- they basically store a list of words, but let see them in action

CREATE FULLTEXT INDEX idx_title_body ON posts (title, body);

 -- in natural language mode
SELECT *
FROM posts
WHERE MATCH (title, body) AGAINST('react redux');

-- to show the relevancy score (from 0 to 1), 0 means no relevance!
SELECT *, MATCH (title, body) AGAINST('react redux') AS Relevancy_Score
FROM posts
WHERE MATCH (title, body) AGAINST('react redux');

 -- in boolean mode similar to google: exclude and include world as required
-- let's exclude "redux" from our search
SELECT *, MATCH (title, body) AGAINST('react redux') AS Relevancy_Score
FROM posts
WHERE MATCH (title, body) AGAINST('react -redux' IN BOOLEAN MODE);

-- the first post that was about redux is no longer in the result!


-- you can also include a word as a requirment using +
SELECT *, MATCH (title, body) AGAINST('react redux') AS Relevancy_Score
FROM posts
WHERE MATCH (title, body) AGAINST('react -redux +form' IN BOOLEAN MODE);

-- search for an exact match
SELECT *, MATCH (title, body) AGAINST('react redux') AS Relevancy_Score
FROM posts
WHERE MATCH (title, body) AGAINST('"handling a form"' IN BOOLEAN MODE);

-- remember for shorter string use prefix indexes!

-- ****************************[Composite Indexes]**********************
-- let's go back to sql_store db and look at the indexes in the customers tabel
USE sql_store;
SHOW INDEXES IN customers;

-- we have one primary and three secondary indexes

-- for this experiment we add an index on points and states columns 
CREATE INDEX idx_points ON customers (points);
CREATE INDEX idx_points ON customers (states);

-- let's say we want to look for customers in CA who have more than 1000 points, how do you write this query?
-- use EXPLAIN to see how mysql will execute this query

EXPLAIN SELECT customer_id 
FROM customers
WHERE state = 'CA' 
AND points > 1000;

-- out of two posible indexes, mysql always picks one.
-- no matter how many indexes we have, mysql always picks maximum one
-- 112 rows need to be scanned fully!
-- but what if we have 1000s of customers in CA! the index only does half of the job
-- composit index will come to the rescue!

-- let's create a composit index on the states and points columns

CREATE INDEX idx_state_points ON customers (state, points);

-- you might be asking if the order matters, it actually does and we will talk about it later

EXPLAIN SELECT customer_id 
FROM customers
WHERE state = 'CA' 
AND points > 1000;

-- 58! now it is better

-- we should drop extera indexes
DROP INDEX idx_state ON customers;
DROP INDEX idx_points ON customers; 
DROP INDEX idx_lastname ON customers; 

SHOW INDEXES IN customers;


-- ****************************[Order of Columns in Composite Indexes]**********************
-- Now we are going to talk about the Order of Columns in Composite Indexes
-- here we have two basic rules
-- 1) put the more frequetly used column first, because it helps narrow down our searches in most of the time!
-- 2) put the column with the higher cardinality first

SHOW INDEXES IN customers;


-- Extra Rule!) always take your queries into account, because sometimes these rules doesn't work!
-- try to understand how mysql exe your queries with different indexes
-- in practice you are not going to come up with one compound indexes that speed up all your queries
-- as your table gorws you migh need to update your indexes based on your new data


-- let's add indexes for state and points
CREATE INDEX idx_points ON customers (points);
CREATE INDEX idx_state ON customers (state);
CREATE INDEX idx_lastname ON customers (last_name);

-- we don't need idx_state_points in this part
DROP INDEX idx_state_points ON customers; 


-- look at the cardinalities of each index 
SHOW INDEXES IN customers;

-- accouding to our second rule idx_lastname is a better candidate to come first, right?
-- because it can break down our table into smaller segments
-- but as we will see, it is not always the best practice!

-- suppose we want to run this query, which column should come first in our index?
SELECT customer_id
FROM customers
WHERE state = 'CA' AND last_name LIKE 'A%';

-- let's look at the cordinaliry of these two columns
-- we are going to count how many unique values we have in each column:

SELECT COUNT(DISTINCT state), COUNT(DISTINCT last_name)
FROM customers;

-- according to our second rule last_name should come first!
-- but as we will see soon cardinality is not always the best practice and we should take the query into account!


-- let's add a composit index, starting with lastname
CREATE INDEX idx_lastname_state ON customers (last_name, state);

-- use explain to see more info
EXPLAIN SELECT customer_id
FROM customers
WHERE state = 'CA' AND last_name LIKE 'A%';


-- 40! we could have several people starting their lastname with A
-- what if we reverse the order of these columns
CREATE INDEX idx_state_lastname ON customers (state,last_name);

-- 7! significant improvment

-- as I said it all depends on your quries, let's change the query to this and get the explanation
-- force to use idx_state_lastname
-- search in range of states using LIKE

EXPLAIN SELECT customer_id
FROM customers
USE INDEX (idx_state_lastname)
WHERE state LIKE 'A%' AND last_name LIKE 'A%';

-- 51 rows

-- force to use idx_lastname_state
EXPLAIN SELECT customer_id
FROM customers
USE INDEX (idx_lastname_state)
WHERE state LIKE 'A%' AND last_name LIKE 'A%';

-- 40 rows
-- so always investigate and see how mysql works with your critical queries (not all quarirs in the world!)

-- ****************************[When Indexes are Ignored]**********************
-- there are situations where you have indexes but you still experience performance problems
-- let's look at one of the common senarios

-- frist let's bring this index back
CREATE INDEX idx_state_points ON customers (state, points);


EXPLAIN SELECT customer_id FROM customers
WHERE state = 'CA' OR points > 1000;

-- even though we used index, we still need to scan all rows!

-- how can we optimize this query? we have to rewire the query to utilize indexes in the best possible way 

-- we break the query into two smaller queries and then use UNION 


	EXPLAIN 
		SELECT customer_id FROM customers
		WHERE state = 'CA' 
		UNION 
		SELECT customer_id FROM customers
		WHERE points > 1000;
        
-- idx_state is used in the first part of the query

-- to speed up the second part of the query we need to create a new index in points:
CREATE INDEX idx_points ON customers (points);

-- idx_point is used in the second part of the query
-- in total we need to scan 641 rows not all rows!


-- let's look at another example
EXPLAIN SELECT customer_id FROM customers
WHERE points + 10 > 2010;

-- to speed up the index for this query, we isolate our columns like this:
EXPLAIN SELECT customer_id FROM customers
WHERE points > 2000;

-- ****************************[Performance Best Practices]**********************
-- in the presentation

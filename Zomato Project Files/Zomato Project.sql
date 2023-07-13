CREATE DATABASE ZOMATO;
USE ZOMATO;

drop table if exists goldusers_signup;

CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(
userid, gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-02-09'),
(2,'2015-01-15'),
(3,'2014-11-04');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- 1 what is the total amount each customer spends on tomato?

SELECT sales.userid, SUM(product.price) AS totalamountspent FROM sales 
JOIN product 
ON sales.product_id = product.product_id
GROUP BY sales.userid;

-- 2 how many days each customer visits zomato website?

SELECT userid, count(distinct(created_date)) as NumberOfDaysVisited FROM sales
GROUP BY userid;

-- 3 what is the name of the first product purchased by each customer?

SELECT * FROM
(SELECT *,RANK() OVER(PARTITION BY userid ORDER BY created_date) rnk FROM sales) a WHERE rnk = 1;

-- 4 what is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT userid, count(product_id) cnt FROM sales WHERE product_id = 
(SELECT product_id FROM sales 
GROUP BY product_id 
ORDER BY count(product_id) desc limit 1)
GROUP BY userid; 

-- 5 which item was the most popular for each customer?

SELECT * FROM (SELECT *, RANK()OVER(PARTITION BY userid ORDER BY cnt DESC) rnk FROM 
(SELECT userid, product_id, count(product_id) cnt FROM sales 
GROUP BY userid, product_id) a) b WHERE rnk = 1;

-- 6 which item was purchased first by the customer after they became a member?

SELECT * FROM (SELECT c.*, RANK()OVER(PARTITION BY userid ORDER BY created_date) rnk FROM 
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date FROM sales a
INNER JOIN goldusers_signup b
ON a.userid = b.userid and a.created_date >= b.gold_signup_date) c) d WHERE rnk = 1;

-- 7 which item was purchased just before the customer became a member?

SELECT * FROM (SELECT c.*, RANK()OVER(PARTITION BY userid ORDER BY created_date) rnk FROM 
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date FROM sales a
INNER JOIN goldusers_signup b
ON a.userid = b.userid and a.created_date <= b.gold_signup_date) c) d WHERE rnk = 1;

-- 8 what is the total order & amount spent by each member before they became a member?

SELECT e.* FROM
(SELECT userid, count(d.product_id) total_order, sum(d.price) total_price FROM 
(SELECT c.*, d.price FROM 
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date FROM sales a
INNER JOIN goldusers_signup b
ON a.userid = b.userid AND a.created_date <= b.gold_signup_date)c
INNER JOIN product d 
ON c.product_id = d.product_id) d
GROUP BY userid) e
ORDER BY userid ;

-- 9 if buying each product generates points for example 5rs = 5 zomato points and each product has different 
-- purchasing points for example for P1 

-- calculate for which product most points have been given?

SELECT * FROM 
(SELECT *,RANK() OVER (ORDER BY totalpointsearned DESC) rnk FROM
(SELECT product_id, SUM(total_points) totalpointsearned FROM
(SELECT e.*, amt/points total_points FROM
(SELECT d.*, 
CASE WHEN product_id = 1 THEN 5 
WHEN product_id = 2 THEN 2 
WHEN product_id = 3 THEN 5 
ELSE 0 END AS points FROM
(SELECT c.userid, c.product_id, sum(price) amt FROM
(SELECT a.*, b.price FROM sales a 
INNER JOIN product b
ON a.product_id = b.product_id) c 
GROUP BY userid, product_id)d)e)f
GROUP BY product_id)g)h WHERE rnk =1 ;

-- calculate the total points collected by each customer?

SELECT userid, SUM(total_points) points_earned FROM
(SELECT e.*, amt/points total_points FROM
(SELECT d.*, 
CASE WHEN product_id = 1 THEN 5 
WHEN product_id = 2 THEN 2 
WHEN product_id = 3 THEN 5 
ELSE 0 END AS points FROM
(SELECT c.userid, c.product_id, sum(price) amt FROM
(SELECT a.*, b.price FROM sales a 
INNER JOIN product b
ON a.product_id = b.product_id) c 
GROUP BY userid, product_id) d)e)f  
GROUP BY userid;

-- 10 In the first one year after the customer joins the gold program (including the join date) irrespective of 
-- what the customer purchased, they earn 5 zomato points for evry 10RS spent, who earned more btw customers with
-- user id 1 and user id 3 and what was their point earnings in their first year?

SELECT c.*, d.price*0.5 total_point_earned FROM
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date FROM sales a
INNER JOIN goldusers_signup b
ON a.userid = b.userid AND a.created_date >= b.gold_signup_date AND created_date <= DATE_ADD(gold_signup_date, INTERVAL 1 YEAR))c
INNER JOIN product d ON c.product_id = d.product_id;

-- 11. Rank all the transactions of the customers 

SELECT *,RANK()OVER (PARTITION BY userid ORDER BY created_date) rnk FROM sales;

-- 12 Rank all the transaction for each member when they are a zomato gold member for every non gold member mark
-- as NA

SELECT e.*, CASE WHEN rnk=0 THEN 'NA' ELSE rnk END AS rnkk FROM
(SELECT c.*, CAST((CASE WHEN gold_signup_date IS NULL THEN 0 ELSE RANK()OVER(PARTITION BY userid ORDER BY created_date DESC) END) AS CHAR) AS rnk FROM
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date FROM sales a
LEFT JOIN goldusers_signup b
ON a.userid = b.userid AND a.created_date >= b.gold_signup_date AND created_date)c)e;
 

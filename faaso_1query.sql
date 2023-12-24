drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date timestamp); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time timestamp,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2021 21:30:45','25km','25mins',null),
(8,2,'01-10-2021 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2021 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date timestamp);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');



select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;


--how many rolls were ordered
select count(*) from customer_orders;

--how many unique customer order were made
select count(distinct customer_id) from customer_orders;


--how many succesful order delivered by each driver
select driver_id, count(order_id) as total
from driver_order
where cancellation not in ('Cancellation','Customer Cancellation')
group by driver_id;

--how many of each type of roll delivered
select c.roll_id, count(roll_id)
from customer_orders as c join driver_order as d on c.order_id=d.order_id where
cancellation not in ('Cancellation','Customer Cancellation') 
group by c.roll_id;


--how many non-veg and veg roll oredered by customer
select c.customer_id,c.roll_id, count(c.roll_id) as total, r.roll_name
from customer_orders as c join rolls as r on c.roll_id=r.roll_id
group by c.customer_id,c.roll_id, r.roll_name
order by c.roll_id;


--max no of rolls delivered in single order
with ct1 as
(
select *, 
case when cancellation in ('Cancellation','Customer Cancellation') then 'cl' else 'nl' end as step
 from driver_order 
),
ct2 as
(
select ct1.order_id,ct1.driver_id,c.customer_id, c.roll_id
from ct1 left join customer_orders as c on ct1.order_id=c.order_id
where ct1.step<>'cl;'
)
select ct2.order_id, count(roll_id) as Total
from ct2
group by ct2.order_id
order by total desc
limit 1;


--for each customer, how many ''delivered'' rolls have at least 1 changes
with ct1 as
(
	--at least one changes in in order
select *, case when (not_include_items is null or not_include_items='') and (extra_items_included is null or extra_items_included ='NaN' or extra_items_included='') then '0' else '1' end as changes 
from customer_orders 
)
--changes in delivered rolls
select ct1.customer_id, ct1.changes, count(case when ct1.changes='0' then 1 else 0 end) as total
from ct1 join driver_order as d on ct1.order_id=d.order_id where
cancellation not in ('Cancellation','Customer Cancellation') or cancellation is null
group by ct1.customer_id, ct1.changes
order by ct1.customer_id;


--how many order DELIVERED that had both the change or either in one
with ct1 as
(
	--assign tha has changes with 1 else '0'
select *, case when (not_include_items is null or not_include_items='') then 1 else 0 end as change_1
, case when (extra_items_included is null or extra_items_included ='NaN' or extra_items_included='') then 1 else 0 end as changes 
from customer_orders 
),
ct2 as
(
	--the order that is delivered
select ct1.*,d.cancellation, case when ct1.change_1=0 and ct1.changes=0 then 'Both' else 'Either One' end as change
from ct1 join driver_order as d on ct1.order_id=d.order_id where
cancellation not in ('Cancellation','Customer Cancellation') or cancellation is null
)
   --total count that has change in both or either in one
select ct2.change, count(1) as Total
from ct2
group by ct2.change;


  --total no of rolls ordered in EACH HOUR OF THE DAY
with ct1 as 
(
select *, concat(extract(hour from order_date),'-',extract(hour from order_date)+1) as hours_bucket  
	from customer_orders
)
select ct1.hours_bucket, count(1)
from ct1
group by ct1.hours_bucket;


with ct1 as
(
select *, to_char(order_date,'day') Days from customer_orders
)
select Days, count(distinct order_id) Total_Orders from ct1 
group by Days;


--diff between order time and pickup time
select * from
(
select *, row_number() over(partition by a.order_id order by a.date_part) as rank
from(
select d.*,c.order_date,  c.customer_id, c.roll_id, date_part('MINUTE',d.pickup_time::timestamp-c.order_date::timestamp)
from driver_order as d inner join customer_orders as c on d.order_id=c.order_id
where d.pickup_time is not null
) as a
) as b where b.rank=1;






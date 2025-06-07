
1 --What is the total amount each customer spent at the restaurant? 
	select s.customer_id, sum(m.price)::money as amount_spent  from sales as s
	join menu as m on s.product_id=m.product_id group by s.customer_id order by s.customer_id

2 --How many days has each customer visited the restaurant?
	select customer_id, count(distinct order_date) from sales group by customer_id

3  --What was the first item from the menu purchased by each customer?
	with temp as(
 	select s.customer_id, m.product_name, s.order_date, dense_rank()over
 	(partition by customer_id order by order_date)as rank from sales as s
 	join menu as m on s.product_id=m.product_id group by customer_id, product_name, order_date )
 	select * from temp where rank=1

4. --What is the most purchased item on the menu and how many times was it purchased by all customers?
	SELECT m.product_name, count(s.product_id) from sales as s
  	join menu as m on s.product_id=m.product_id group by product_name order by count desc limit 1 

5 --Which item was the most popular for each customer?
	with temp as(
	select distinct s.customer_id,  m.product_name, count(s.product_id),
	rank() over(partition by customer_id order by count(s.product_id)desc) from
	sales as s join menu as m on s.product_id=m.product_id 
	group by customer_id,product_name order by s.customer_id)
	select customer_id, product_name, count from temp where rank=1

6 --Which item was purchased first by the customer after they became a member?
	with purchases_as_a_member AS(
 	select s.customer_id, s.order_date, m.product_name, t.join_date 
  	from  sales as s join menu as m on s.product_id=m.product_id
  	join members as t on s.customer_id=t.customer_id where s.order_date>=t.join_date)
    select * 
  from(
   select *, rank()over(partition by customer_id order by order_date)as order_rank
   from purchases_as_a_member) as first_purchased_as_member
	  where order_rank<2

7  -- Which item was purchased just before the customer became a member?
	 /*with (just before) we assume danny means the last order before they became a member, 
	 other orders before then were ignored*/
	with purchases_before_a_member AS(
  	select s.customer_id, s.order_date, m.product_name, t.join_date 
 	from  sales as s join menu as m on s.product_id=m.product_id
  	join members as t on s.customer_id=t.customer_id where s.order_date<t.join_date)
    select * 
  	from(
   	select *, rank()over(partition by customer_id order by order_date desc)as order_rank
   	from purchases_before_a_member) as first_purchased_as_member
	where order_rank<2


8. --What is the total items and amount spent for each member before they became a member?
	with temp
	AS(
	 select s.customer_id, s.order_date,m.product_name,m.price,t.join_date
	 from sales as s join menu as m on s.product_id=m.product_id
	 join members as t on s.customer_id=t.customer_id where order_date<join_date 
	)
	 select customer_id, count(product_name)as total_items,
	 sum(price)::money as amount_spent from temp group by customer_id order by customer_id

9 	  /*If each $1 spent equates to 10 points and sushi has a 2x points multiplier
	           - how many points would each customer have?*/
	  with temp1 as(
	  select s.customer_id, m.product_name, count(distinct order_date), sum(m.price)*10 as total_points
	  from sales as s join menu as m on s.product_id=m.product_id 
	  where product_name not ilike'%sushi%'
	  group by 
	  customer_id,product_name),
	  temp2 as(
	   select s.customer_id, m.product_name, count(distinct order_date), sum(m.price)*20 as total_points
	  from sales as s join menu as m on s.product_id=m.product_id 
	  where product_name  ilike'%sushi%'
	  group by 
	  customer_id,product_name)
	  select customer_id, sum(total_points)as points from(
	 ( select * from temp1
	  union all
	  select * from temp2))as temp3 group by customer_id order by customer_id

10  /*In the first week after a customer joins the program (including their join date) 
	  they earn 2x points on all items,
	  not just sushi - how many points do customer A and B have at the end of January?*/
		select s.customer_id, sum(case when s.order_date between me.join_date and me.join_date + 6 then m.price * 20
		when m.product_id = 1
		then m.price * 20  -- 2x points multiplier for sushi
		else m.price * 10
		END) as total_points
	from 
		sales s
	join 
		Menu m on s.product_id = m.product_id
	join
		members me on s.customer_id = me.customer_id
	where s.order_date <= '2021_01_31' -- assuming January 31st as the end date
	group by s.customer_id


					BONUS QUESTIONS

1.  select s.customer_id, s.order_date, m.product_name, m.price,
          CASE
		      when s.order_date<t.join_date then 'N'
			  when s.order_date>=t.join_date then 'Y'
			  else 'N'
			  END as member
  from sales as s left join menu as m on s.product_id=m.product_id
  left join members as t on s.customer_id=t.customer_id
  order by customer_id, member,product_name


2  with rank as(
  select s.customer_id, s.order_date, m.product_name, m.price,
          CASE
		      when s.order_date<t.join_date then 'N'
			  when s.order_date>=t.join_date then 'Y'
			  else 'N'
			  END as member
  from sales as s left join menu as m on s.product_id=m.product_id
  left join members as t on s.customer_id=t.customer_id
  order by customer_id, member,product_name)
   select *, 
   CASE
      when member='N' then null
	  else dense_rank()over(partition by customer_id,member order by order_date)
	  END as ranking
	  from rank

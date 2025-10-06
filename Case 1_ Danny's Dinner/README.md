# Case Study Danny's Dinner
![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/d6fed705-4158-4c6a-9d17-b86e8be16a58)


### **Business Task**
Danny aims to leverage customer data to gain valuable insights into customer behavior, spending patterns, and menu item preferences. This analysis will enable him to enhance the personalized experience for his loyal customers and make informed decisions regarding the expansion of his existing customer loyalty.

### Database Relationship Diagram
![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/74f08e09-c851-46c6-8e0f-dda9018f5d67)

All dataset are within dannys_dinner schema whhich includes:
- sales: The sales table captures all customer_id level purchases with an corresponding order_date and product_id information for when and what menu items were ordered.
- menu: The menu table maps the product_id to the actual product_name and price of each menu item.
- members: The members table captures the join_date when a customer_id joined the beta version of the Danny’s Diner loyalty program.

**sales Table**

![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/82378738-4802-4469-910c-97d1488881ce)

**menu Table**

![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/79fa7e45-0f9f-4e19-80c5-1c795486c84c)

**members Table**

![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/cf205fe8-2a95-44ba-9205-056d1098b55e)

# Case Questions and Answers

1. What is the total amount each customer spent at the restaurant?

```
SELECT 
    a.customer_id, 
    SUM(b.price) AS total_purchase
FROM 
    dannys_diner.sales AS a
JOIN 
    dannys_diner.menu AS b
ON 
    a.product_id = b.product_id
GROUP BY 
    a.customer_id;
```
Results:

![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/0fc07d69-87dc-4a54-bd3c-6424abedc291)

2. How many days has each customer visited the restaurant?
```
SELECT 
    customer_id, 
    COUNT(order_date) AS total_visits
FROM 
    dannys_diner.sales
GROUP BY 
    customer_id;
```
Results:

![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/0b7e3c30-4793-4d6f-805b-90f95b52ce5c)


3. What was the first item from the menu purchased by each customer?
```
SELECT 
    a.customer_id, 
    b.product_name, 
    a.order_date
FROM 
    dannys_diner.sales AS a
JOIN 
    dannys_diner.menu AS b
ON 
    b.product_id = a.product_id
WHERE 
    a.order_date = (
        SELECT MIN(order_date)
        FROM dannys_diner.sales
        WHERE customer_id = a.customer_id
    )
GROUP BY 
    a.customer_id, 
    b.product_name, 
    a.order_date;
```
Results:

![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/0d166234-a971-4f9e-8d3a-a9ccf27074f3)


4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```
SELECT 
    b.product_name, 
    COUNT(a.product_id) AS total_item_purchase
FROM 
    dannys_diner.sales AS a
JOIN 
    dannys_diner.menu AS b
ON 
    a.product_id = b.product_id
GROUP BY 
    b.product_name
ORDER BY 
    total_item_purchase DESC
LIMIT 1;
```
Result: 

![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/96b32a4d-0fbc-4d64-a5f0-752b33b61a29)


5. Which item was the most popular for each customer? 
```
SELECT 
    a.customer_id, 
    a.product_id, 
    b.product_name
FROM 
    dannys_diner.sales AS a
JOIN 
    dannys_diner.menu AS b
ON 
    a.product_id = b.product_id
WHERE 
    a.product_id = (
        SELECT product_id
        FROM (
            SELECT 
                product_id, 
                COUNT(*) AS product_count
            FROM 
                dannys_diner.sales
            WHERE 
                customer_id = a.customer_id
            GROUP BY 
                product_id
            ORDER BY 
                product_count DESC
            LIMIT 1
        ) AS sub
    )
GROUP BY 
    a.customer_id, 
    a.product_id, 
    b.product_name;
```

Results

![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/e72ace19-b3c6-4247-bff0-625947e4d141)

6. Which item was purchased first by the customer after they became a member?
```
SELECT 
    s.customer_id, 
    s.product_id, 
    s.order_date
FROM 
    dannys_diner.sales AS s
JOIN (
    SELECT 
        customer_id, 
        MIN(order_date) AS first_order_date
    FROM 
        dannys_diner.sales
    WHERE 
        order_date >= (
            SELECT join_date 
            FROM dannys_diner.members 
            WHERE members.customer_id = sales.customer_id
        )
    GROUP BY 
        customer_id
) AS first_purchases
ON 
    s.customer_id = first_purchases.customer_id 
AND 
    s.order_date = first_purchases.first_order_date;
```
Results:

![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/a46e0d38-b9a2-417d-a950-29ee47d6fca4)

7. Which item was purchased just before the customer became a member?
```
SELECT 
    a.customer_id, 
    a.product_id, 
    a.order_date
FROM 
    dannys_diner.sales AS a
JOIN (
    SELECT 
        customer_id, 
        MAX(order_date) AS max_date
    FROM 
        dannys_diner.sales
    WHERE 
        order_date < (
            SELECT join_date 
            FROM dannys_diner.members 
            WHERE members.customer_id = sales.customer_id
        )
    GROUP BY 
        customer_id
) AS purchases_before_joining
ON 
    a.customer_id = purchases_before_joining.customer_id 
AND 
    a.order_date = purchases_before_joining.max_date;
```
Results:

![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/320de5f2-a842-4c98-b94d-8d7796232551)


8. What is the total items and amount spent for each member before they became a member?
```
SELECT 
    a.customer_id, 
    total_items, 
    total_purchases
FROM 
    dannys_diner.sales AS a
JOIN (
    SELECT 
        customer_id, 
        COUNT(product_id) AS total_items 
    FROM 
        dannys_diner.sales 
    GROUP BY 
        customer_id
) AS total_items_purchase
ON 
    a.customer_id = total_items_purchase.customer_id
JOIN (
    SELECT 
        a.customer_id, 
        SUM(b.price) AS total_purchases 
    FROM 
        dannys_diner.sales AS a
    JOIN 
        dannys_diner.menu AS b 
    ON 
        a.product_id = b.product_id 
    GROUP BY 
        a.customer_id
) AS total_amount
ON 
    a.customer_id = total_amount.customer_id
GROUP BY 
    a.customer_id;
```
Results:

![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/775a13ae-6188-4cf0-a4a2-a6bd5fd85b36)


9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```
WITH sales_with_prices AS (
    SELECT
        s.customer_id,
        s.order_date,
        m.product_name,
        m.price
    FROM 
        dannys_diner.sales AS s
    JOIN 
        dannys_diner.menu AS m 
    ON 
        s.product_id = m.product_id
),
points_calculation AS (
    SELECT
        customer_id,
        order_date,
        product_name,
        price,
        CASE
            WHEN product_name = 'sushi' THEN price * 20  -- 2x points for sushi (10 points * 2)
            ELSE price * 10  -- 10 points per $1 spent
        END AS points
    FROM 
        sales_with_prices
)
SELECT
    customer_id,
    SUM(points) AS total_points
FROM 
    points_calculation
GROUP BY 
    customer_id;
```

Results:

![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/8ec7e6ce-6133-4ad2-a50c-73e59e56db48)


10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```
WITH sales_with_prices AS (
    SELECT
        s.customer_id,
        s.order_date,
        m.product_name,
        m.price
    FROM 
        dannys_diner.sales AS s
    JOIN 
        dannys_diner.menu AS m 
    ON 
        s.product_id = m.product_id
),
sales_with_membership AS (
    SELECT
        sp.customer_id,
        sp.order_date,
        sp.product_name,
        sp.price,
        m.join_date,
        CASE
            WHEN sp.order_date BETWEEN m.join_date AND DATE_ADD(m.join_date, INTERVAL 6 DAY) THEN 1
            ELSE 0
        END AS first_week
    FROM 
        sales_with_prices AS sp
    LEFT JOIN 
        dannys_diner.members AS m 
    ON 
        sp.customer_id = m.customer_id
),
points_calculation AS (
    SELECT
        customer_id,
        order_date,
        product_name,
        price,
        first_week,
        CASE
            WHEN first_week = 1 THEN price * 20  -- 2x points on all items during first week
            WHEN product_name = 'sushi' THEN price * 20  -- 2x points for sushi
            ELSE price * 10  -- 10 points per $1 spent
        END AS points
    FROM 
        sales_with_membership
)
SELECT
    customer_id,
    SUM(points) AS total_points
FROM 
    points_calculation
WHERE 
    order_date <= '2021-01-31'
GROUP BY 
    customer_id;
```

Results:

![image](https://github.com/gleidyalonzo/SQL_challenges/assets/95588335/c6514228-73ee-4e44-a925-abeb93a5ceef)

## Bonus Questions

11. Recreate the following table output using the available data

![image](https://github.com/gleidyalonzo/8-Weekk-SQL-Challenges/assets/95588335/3055beaf-8474-4641-ad73-3a0cda008849)

```
SELECT 
  a.customer_id, 
  a.order_date,
  b.product_name, 
  b.price,
  CASE
    WHEN a.customer_id IN (SELECT customer_id 
                           FROM dannys_diner.members 
                           WHERE join_date <= a.order_date) THEN 'YES'
    ELSE 'NO'
  END AS member
FROM 
dannys_diner.sales AS a

FULL JOIN dannys_diner.menu AS b 
	ON a.product_id = b.product_id

FULL JOIN
dannys_diner.members as c
ON 
a.customer_id = c.customer_id
order by a.customer_id, a.order_date;
```

Results:
![image](https://github.com/gleidyalonzo/8-Weekk-SQL-Challenges/assets/95588335/456d5515-3a3a-43c7-8e31-b3f560eedda2)

12. Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

```
WITH member_orders AS (
  SELECT 
    a.customer_id, 
    a.order_date,
    b.product_name, 
    b.price,
    CASE
      WHEN a.customer_id IN (SELECT customer_id 
                             FROM dannys_diner.members 
                             WHERE join_date <= a.order_date) THEN 'YES'
      ELSE 'NO'
    END AS member
  FROM 
    dannys_diner.sales AS a
  JOIN 
    dannys_diner.menu AS b 
  ON 
    a.product_id = b.product_id
)
SELECT 
  customer_id, 
  order_date,
  product_name, 
  price,
  member,
  CASE 
    WHEN member = 'YES' THEN 
      DENSE_RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)
    ELSE NULL
  END AS ranks
FROM 
  member_orders
ORDER BY 
  customer_id,
  order_date;
```

Results:

![image](https://github.com/gleidyalonzo/8-Weekk-SQL-Challenges/assets/95588335/261a587b-f5fb-4d73-9876-64c1d8e5bab7)


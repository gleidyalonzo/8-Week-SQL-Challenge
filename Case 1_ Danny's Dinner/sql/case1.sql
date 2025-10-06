/* --------------------
   Case Study Questions
   --------------------*/
   
/* 1. What is the total amount each customer spent at the restaurant? */
SELECT
  s.customer_id,
  SUM(m.price) AS total_purchase
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m ON m.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;


/* 2. How many days has each customer visited the restaurant? */
SELECT
  customer_id,
  COUNT(DISTINCT order_date) AS total_visits
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id;


/* 3. What was the first item from the menu purchased by each customer? */
WITH first_day AS (
  SELECT customer_id, MIN(order_date) AS first_order_date
  FROM dannys_diner.sales
  GROUP BY customer_id
)
SELECT
  s.customer_id,
  m.product_name,
  s.order_date
FROM dannys_diner.sales AS s
JOIN first_day AS f ON f.customer_id = s.customer_id AND f.first_order_date = s.order_date
JOIN dannys_diner.menu AS m ON m.product_id = s.product_id
ORDER BY s.customer_id, m.product_name;


/* 4. What is the most purchased item on the menu and how many times was it purchased by all customers? */
SELECT
  m.product_name,
  COUNT(*) AS total_item_purchase
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m ON m.product_id = s.product_id
GROUP BY m.product_name
ORDER BY total_item_purchase DESC, m.product_name
LIMIT 1;


/* 5. Which item was the most popular for each customer? */
WITH counts AS (
  SELECT s.customer_id, s.product_id, COUNT(*) AS cnt
  FROM dannys_diner.sales AS s
  GROUP BY s.customer_id, s.product_id
),
ranked AS (
  SELECT
    c.*,
    DENSE_RANK() OVER (PARTITION BY c.customer_id ORDER BY c.cnt DESC) AS rnk
  FROM counts AS c
)
SELECT
  r.customer_id,
  r.product_id,
  m.product_name
FROM ranked AS r
JOIN dannys_diner.menu AS m ON m.product_id = r.product_id
WHERE r.rnk = 1
ORDER BY r.customer_id, m.product_name;


/* 6. Which item was purchased first by the customer after they became a member? */
WITH after_join AS (
  SELECT s.customer_id, s.order_date, s.product_id
  FROM dannys_diner.sales AS s
  JOIN dannys_diner.members AS mb ON mb.customer_id = s.customer_id
  WHERE s.order_date >= mb.join_date
),
first_after AS (
  SELECT customer_id, MIN(order_date) AS first_order_after_join
  FROM after_join
  GROUP BY customer_id
)
SELECT
  a.customer_id,
  a.product_id,
  m.product_name,
  a.order_date
FROM after_join AS a
JOIN first_after AS f ON f.customer_id = a.customer_id AND f.first_order_after_join = a.order_date
JOIN dannys_diner.menu AS m ON m.product_id = a.product_id
ORDER BY a.customer_id, m.product_name;


/* 7. Which item was purchased just before the customer became a member? */
WITH before_join AS (
  SELECT s.customer_id, s.order_date, s.product_id
  FROM dannys_diner.sales AS s
  JOIN dannys_diner.members AS mb ON mb.customer_id = s.customer_id
  WHERE s.order_date < mb.join_date
),
last_before AS (
  SELECT customer_id, MAX(order_date) AS last_order_before_join
  FROM before_join
  GROUP BY customer_id
)
SELECT
  b.customer_id,
  b.product_id,
  m.product_name,
  b.order_date
FROM before_join AS b
JOIN last_before AS l ON l.customer_id = b.customer_id AND l.last_order_before_join = b.order_date
JOIN dannys_diner.menu AS m ON m.product_id = b.product_id
ORDER BY b.customer_id, m.product_name;


/* 8. What is the total items and amount spent for each member before they became a member? */
SELECT
  s.customer_id,
  COUNT(*)     AS total_items,
  SUM(m.price) AS total_amount_spent
FROM dannys_diner.sales AS s
JOIN dannys_diner.members AS mb ON mb.customer_id = s.customer_id
JOIN dannys_diner.menu AS m ON m.product_id = s.product_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;


/* 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? */
SELECT
  s.customer_id,
  SUM(
    CASE 
      WHEN m.product_name = 'sushi' THEN m.price * 20
      ELSE m.price * 10
    END
  ) AS total_points
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m ON m.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;


/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? */
WITH sw AS (
  SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    mb.join_date,
    CASE
      WHEN mb.join_date IS NOT NULL
       AND s.order_date BETWEEN mb.join_date AND (mb.join_date + INTERVAL '6 days')
      THEN TRUE ELSE FALSE
    END AS in_first_week
  FROM dannys_diner.sales AS s
  JOIN dannys_diner.menu AS m ON m.product_id = s.product_id
  LEFT JOIN dannys_diner.members AS mb ON mb.customer_id = s.customer_id
)
SELECT
  customer_id,
  SUM(
    CASE
      WHEN order_date <= DATE '2021-01-31' THEN
        CASE
          WHEN in_first_week          THEN price * 20
          WHEN product_name = 'sushi' THEN price * 20
          ELSE                             price * 10
        END
      ELSE 0
    END
  ) AS total_points
FROM sw
WHERE customer_id IN ('A','B')
GROUP BY customer_id
ORDER BY customer_id;


/* 11. Join all thing Recreate the following table output using the available data */
SELECT
  s.customer_id,
  s.order_date,
  m.product_name,
  m.price,
  CASE
    WHEN mb.join_date IS NOT NULL AND s.order_date >= mb.join_date THEN 'YES'
    ELSE 'NO'
  END AS member
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m ON m.product_id = s.product_id
LEFT JOIN dannys_diner.members AS mb ON mb.customer_id = s.customer_id
ORDER BY s.customer_id, s.order_date, m.product_name;


/* 12. Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program. */
WITH member_orders AS (
  SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
      WHEN mb.join_date IS NOT NULL AND s.order_date >= mb.join_date THEN 'YES'
      ELSE 'NO'
    END AS member
  FROM dannys_diner.sales AS s
  JOIN dannys_diner.menu AS m ON m.product_id = s.product_id
  LEFT JOIN dannys_diner.members AS mb ON mb.customer_id = s.customer_id
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
FROM member_orders
ORDER BY customer_id, order_date, product_name;

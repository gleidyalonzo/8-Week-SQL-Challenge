-- ================================
-- Pizza Runner Analysis Checklist
-- ================================
-- A. Pizza Metrics
-- 1) How many pizzas were ordered?

SELECT count(order_id) as total_pizzas_ordered
FROM [pizza_runner].[customer_orders];

-- 2) How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) as unique_customer_orders
FROM [pizza_runner].[customer_orders];

-- 3) How many successful orders were delivered by each runner?

SELECT runner_id, COUNT(order_id) as delivered_orders
FROM [pizza_runner].[runner_orders]
WHERE pickup_time != 'null' -- This field contains 'null' values recorded as a string, these values represent cancelled orders
GROUP BY runner_id;

-- 4) How many of each type of pizza was delivered?

SELECT a.pizza_name, COUNT(b.pizza_id) total_pizzas_delivered
FROM [pizza_runner].[customer_orders] b
JOIN [pizza_runner].[pizza_names] a
ON  a.pizza_id =  b.pizza_id
WHERE b.order_id NOT IN (
    SELECT DISTINCT order_id
    FROM pizza_runner.runner_orders
    WHERE pickup_time = 'null' -- This field contains 'null' values recorded as a string, these values represent cancelled orders
)
GROUP BY a.pizza_name

-- 5) How many Vegetarian and Meatlovers were ordered by each customer?
-- Option 1 is a long format
SELECT a.customer_id, b.pizza_name, COUNT(b.pizza_id) as total_pizzas_ordered
FROM [pizza_runner].[customer_orders] a 
JOIN [pizza_runner].[pizza_names] b
ON a.pizza_id = b.pizza_id
GROUP BY a.customer_id, b.pizza_name
ORDER BY a.customer_id, b.pizza_name;

--- Option 2 is a wide format

SELECT 
    customer_id,
    COUNT(CASE WHEN pizza_id = 1 THEN 1 END) AS Meatlovers,
    COUNT(CASE WHEN pizza_id = 2 THEN 1 END) AS Vegetarian
FROM [pizza_runner].[customer_orders]
GROUP BY customer_id
ORDER BY customer_id;


-- 6) What was the maximum number of pizzas delivered in a single order?

-- Using SELECT TOP (1) returns only one order with the highest number of pizzas delivered.
SELECT top (1) order_id, COUNT(pizza_id) as total_pizzas_delivered
FROM [pizza_runner].[customer_orders]
WHERE order_id NOT IN (
    SELECT DISTINCT order_id
    FROM pizza_runner.runner_orders
    WHERE pickup_time = 'null' -- This field contains 'null' values recorded as a string, these values represent cancelled orders
)
GROUP BY order_id
order by total_pizzas_delivered DESC;

-- Using SELECT TOP (1) WITH TIES returns all orders that are tied for the highest number of pizzas delivered.
;WITH PizzaCounts AS (
    SELECT order_id, COUNT(pizza_id) AS total_pizzas_delivered
    FROM [pizza_runner].[customer_orders]
    WHERE order_id NOT IN (
        SELECT DISTINCT order_id
        FROM pizza_runner.runner_orders
        WHERE pickup_time = 'null' -- recorded as the string 'null' for cancelled orders
    )
    GROUP BY order_id
)
SELECT top (1) WITH TIES order_id, total_pizzas_delivered
FROM PizzaCounts
ORDER BY total_pizzas_delivered DESC;

-- 7) For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT a.customer_id,
         SUM(CASE WHEN (a.exclusions IS NOT NULL AND LTRIM(RTRIM(a.exclusions)) != 'null') OR (a.extras IS NOT NULL AND LTRIM(RTRIM(a.extras)) != 'null') THEN 1 ELSE 0 END) AS pizzas_with_changes,
         SUM(CASE WHEN (a.exclusions IS NULL OR LTRIM(RTRIM(a.exclusions)) = 'null') AND (a.extras IS NULL OR LTRIM(RTRIM(a.extras)) = 'null') THEN 1 ELSE 0 END) AS pizzas_without_changes
FROM [pizza_runner].[customer_orders] a
JOIN [pizza_runner].[runner_orders] c
ON a.order_id = c.order_id
WHERE c.pickup_time IS NOT NULL OR LTRIM(RTRIM(pickup_time)) != 'null' -- Exclude cancelled orders
GROUP BY a.customer_id
ORDER BY a.customer_id;

-- 8) How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(a.pizza_id) as pizzas_with_exclusions_and_extras
FROM [pizza_runner].[customer_orders] a
JOIN [pizza_runner].[runner_orders] c
ON a.order_id = c.order_id
WHERE (a.exclusions IS NOT NULL AND LTRIM(RTRIM(a.exclusions)) not in ('null', ' '))
  AND (a.extras IS NOT NULL AND LTRIM(RTRIM(a.extras)) not in ('null', ' '))
  AND (c.pickup_time IS NOT NULL AND LTRIM(RTRIM(c.pickup_time)) != 'null'); -- Exclude cancelled orders

-- 9) What was the total volume of pizzas ordered for each hour of the day?
SELECT DATEPART(HOUR, order_time) as order_hour, COUNT(order_id) as total_pizzas_ordered
FROM [pizza_runner].[customer_orders]
GROUP BY DATEPART(HOUR, order_time)
ORDER BY order_hour;

-- 10) What was the volume of orders for each day of the week?
SELECT DATENAME(WEEKDAY, order_time) as order_day, COUNT(order_id) as total_pizzas_ordered
FROM [pizza_runner].[customer_orders]
GROUP BY DATENAME(WEEKDAY, order_time), DATEPART(WEEKDAY, order_time)
ORDER BY DATEPART(WEEKDAY, order_time);


-- B. Runner and Customer Experience
-- 1) How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
-- 2) What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-- 3) Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- 4) What was the average distance travelled for each customer?
-- 5) What was the difference between the longest and shortest delivery times for all orders?
-- 6) What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- 7) What is the successful delivery percentage for each runner?

-- C. Ingredient Optimisation
-- 1) What are the standard ingredients for each pizza?
-- 2) What was the most commonly added extra?
-- 3) What was the most common exclusion?
-- 4) Generate an order item for each record in the customers_orders table in the format of one of the following:
--    - Meat Lovers
--    - Meat Lovers - Exclude Beef
--    - Meat Lovers - Extra Bacon
--    - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
-- 5) Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table
--    and add a 2x in front of any relevant ingredients (e.g., "Meat Lovers: 2xBacon, Beef, ... , Salami").
-- 6) What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

-- D. Pricing and Ratings
-- 1) If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes,
--    how much money has Pizza Runner made so far if there are no delivery fees?
-- 2) What if there was an additional $1 charge for any pizza extras? (Add cheese is $1 extra)
-- 3) The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner.
--    Design a table schema and insert ratings (1–5) for each successful customer order.
-- 4) Using the newly generated table, join all information for successful deliveries to produce:
--    customer_id, order_id, runner_id, rating, order_time, pickup_time, time between order and pickup,
--    delivery duration, average speed, total number of pizzas.
-- 5) If Meat Lovers is $12 and Vegetarian $10 (no cost for extras) and runners are paid $0.30/km,
--    how much money does Pizza Runner have left after these deliveries?

-- E. Bonus Questions
-- 1) If Danny adds more pizzas, how does this impact the data design?
--    Write an INSERT to add a new 'Supreme' pizza with all toppings to the menu.

-- Conclusion

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
SELECT DATEADD(WEEK, DATEDIFF(WEEK, 0, registration_date), 0) as signup_week_start,
       COUNT(runner_id) as total_runners_signed_up
FROM [pizza_runner].[runners]
GROUP BY DATEADD(WEEK, DATEDIFF(WEEK, 0, registration_date), 0)
ORDER BY signup_week_start;

-- Explanation: 
-- It calculates the start date of the week for each signup_date by using DATEADD and DATEDIFF functions, it will give you  the starting date of the week that each registration falls into.
-- It then groups the results by this calculated week start date and counts the number of runners who signed up in each week.

-- 2) What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

WITH RunnerPickupTravelTime AS (
    SELECT DISTINCT
        a.order_id,
        a.runner_id,
        a.pickup_time,
        b.order_time,
        DATEDIFF(minute, b.order_time, pickup_time) AS pickup_travel_time
    FROM pizza_runner.runner_orders AS a
    LEFT JOIN pizza_runner.customer_orders AS b
        ON a.order_id = b.order_id
    WHERE a.pickup_time != 'null'
)
SELECT
    runner_id,
    AVG(pickup_travel_time * 1.0) AS average_pickup_time
FROM RunnerPickupTravelTime
GROUP BY runner_id;

-- Explanation:
-- The CTE RunnerPickupTravelTime calculates the travel time for each order by finding the difference in minutes between the order_time and pickup_time.
-- The main query then averages these travel times for each runner.
-- Note: Multiplying by 1.0 ensures that the average is returned as a decimal value.
-- pcikup_time field contains 'null' values recorded as a string, these values represent cancelled orders

-- 3) Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH OrderPizzaCounts AS (
    SELECT 
        a.order_id,
        COUNT(a.pizza_id) AS pizza_count,
        DATEDIFF(minute, b.order_time, a.pickup_time) AS preparation_time
    FROM pizza_runner.runner_orders AS a
    JOIN pizza_runner.customer_orders AS b
        ON a.order_id = b.order_id
    WHERE a.pickup_time != 'null' -- Exclude cancelled orders
    GROUP BY a.order_id, b.order_time, a.pickup_time
)
SELECT 
    pizza_count,
    AVG(preparation_time * 1.0) AS average_preparation_time
FROM OrderPizzaCounts
GROUP BY pizza_count
ORDER BY pizza_count;
-- Explanation:
-- The more pizza an order has, the longer it generally takes to prepare.
-- The CTE OrderPizzaCounts calculates the number of pizzas and preparation time for each order.
-- The main query then averages the preparation times grouped by the number of pizzas in the order.

-- 4) What was the average distance travelled for each customer?
WITH CustomerDistances AS (
    SELECT 
        a.order_id,
        b.customer_id,
        CAST(REPLACE(a.distance, 'km', '') AS FLOAT) AS distance_km
    FROM pizza_runner.runner_orders AS a
    JOIN pizza_runner.customer_orders AS b
        ON a.order_id = b.order_id
    WHERE a.pickup_time != 'null' -- Exclude cancelled orders
)
SELECT 
    customer_id,
    AVG(distance_km * 0.1) AS average_distance_km
FROM CustomerDistances
GROUP BY customer_id
ORDER BY customer_id;
-- Explanation:
-- The CTE CustomerDistances extracts the numeric distance in kilometers for each order by removing the '
-- km' suffix and converting it to a FLOAT.
-- The main query then averages these distances for each customer.
--  Note: The distance field contains 'null' values recorded as a string, these values represent cancelled orders

-- 5) What was the difference between the longest and shortest delivery times for all orders?

WITH DeliveryTimes AS (
    SELECT 
        order_id,
        TRY_CAST(
            REPLACE(
                TRANSLATE(
                    duration,
                    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
                    '                                                    ' -- 52 spaces
                ),
                ' ',
                ''
            ) AS INT
        ) AS delivery_time
    FROM [pizza_runner].[runner_orders]
    WHERE pickup_time <> 'null'
)
SELECT 
    MAX(delivery_time) - MIN(delivery_time) AS delivery_time_difference
FROM DeliveryTimes;
-- Explanation:
-- The CTE DeliveryTimes extracts the numeric delivery time in minutes for each order by removing all alphabetic characters from the duration field.
-- The main query then calculates the difference between the maximum and minimum delivery times.
-- Note: The pickup_time field contains 'null' values recorded as a string, these values represent cancelled orders
-- REPLACE is used to clean the duration field to extract numeric values, the TRANSLATE is used to remove all alphabetic characters.
-- try_cast is used to handle any non-numeric values that may arise after cleaning the duration field.

-- 6) What was the average speed for each runner for each delivery and do you notice any trend for these values?
WITH RunnerSpeeds AS (
    SELECT 
        order_id,
        runner_id,
        CAST(REPLACE(trim(distance), 'km', '') AS FLOAT) AS distance_km,
       REPLACE(
        TRANSLATE(
            duration,
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
            '                                                    ' -- 52 spaces
        ),
        ' ',
        '')  as delivery_time 
    FROM [pizza_runner].[runner_orders]
    WHERE pickup_time != 'null' -- Exclude cancelled orders
)
SELECT 
    runner_id,
    order_id,
    distance_km,
    delivery_time,
   (distance_km / delivery_time) * 60  AS average_speed_kmh
FROM RunnerSpeeds
ORDER BY runner_id, order_id;
-- Explanation:
-- The CTE RunnerSpeeds extracts the numeric distance in kilometers and delivery time in minutes for each order by removing the 'km' suffix from distance and stripping non-numeric characters from duration.
-- The main query then calculates the average speed in km/h for each delivery by dividing distance by delivery time (converted to hours).
-- Note: The pickup_time field contains 'null' values recorded as a string, these values represent cancelled orders
-- REPLACE is used to clean the duration field to extract numeric values, the TRANSLATE is used to remove all alphabetic characters.

-- 7) What is the successful delivery percentage for each runner?
WITH RunnerDeliveryStats AS (
    SELECT 
        runner_id,
        COUNT(order_id) AS total_orders,
        SUM(CASE WHEN pickup_time != 'null' THEN 1 ELSE 0 END) AS successful_deliveries
    FROM [pizza_runner].[runner_orders]
    GROUP BY runner_id
)
SELECT 
    runner_id,
    successful_deliveries,
    total_orders,
    (successful_deliveries * 1.0 / total_orders) * 100 AS successful_delivery_percentage
FROM RunnerDeliveryStats
ORDER BY runner_id;

-- Explanation:
-- The CTE RunnerDeliveryStats calculates the total number of orders and successful deliveries for each runner.
-- The main query then calculates the successful delivery percentage by dividing successful deliveries by total orders and multiplying
-- by 100 to get a percentage.
-- whats considered a successful delivery is determined by whether pickup_time is not equal to 'null' (string), which indicates the order was not cancelled.

-- C. Ingredient Optimisation
-- 1) What are the standard ingredients for each pizza?
SELECT pizza_name, STRING_AGG(ingredient_name, ', ') -- left a whitespace after the comma
FROM (
SELECT pn.pizza_name, pt.topping_name AS ingredient_name
FROM [pizza_runner].[pizza_names] pn 
-- Table containing pizza names and their unique pizza_id

JOIN [pizza_runner].[pizza_recipes] pr 
  ON pn.pizza_id = pr.pizza_id 
-- Table linking each pizza_id to its recipe.
-- The 'toppings' column stores topping IDs as a comma-separated string (e.g., '1,2,3')

JOIN [pizza_runner].[pizza_toppings] pt 
  ON CAST(pt.topping_id AS VARCHAR) 
     IN (
         SELECT TRIM(value) 
         FROM STRING_SPLIT(pr.toppings, ',')
     )
-- This join matches each topping_id from the toppings table to the list of topping IDs in the recipe.
-- Here's how it works:
-- 1. STRING_SPLIT(pr.toppings, ',') breaks the comma-separated string into individual values.
--    Example: '1, 2, 3' becomes rows: '1', ' 2', ' 3'
-- 2. TRIM(value) removes any leading/trailing spaces from each split value.
-- 3. CAST(pt.topping_id AS VARCHAR) converts the integer topping_id to a string
--    so it can be compared to the string values from STRING_SPLIT.
) AS ingredients
GROUP BY pizza_name

-- Why CAST is needed:
-- STRING_SPLIT returns strings, not integers.
-- Without casting, SQL Server would compare an integer to a string, which fails.

--- Notes on portability:
-- - SQL Server uses STRING_SPLIT; other databases use different functions:
--   - PostgreSQL: UNNEST(string_to_array(...))
--   - MySQL: Use JSON functions or custom split routines
--   - Oracle: REGEXP_SUBSTR or XMLTABLE
-- - Always check how your database handles string splitting and type casting.

-- Tip: When querying comma-separated values, treat them as semi-structured data.
-- The goal is to extract and normalize them within the query, not redesign the schema.

-- 2) What was the most commonly added extra?
SELECT topping_name, COUNT(*) AS extra_count
FROM (
    SELECT 
        co.extras,
        TRIM(value) AS topping_id
    FROM [pizza_runner].[customer_orders] AS co
    CROSS APPLY STRING_SPLIT(co.extras, ',')
    WHERE co.extras IS NOT NULL 
      AND LTRIM(RTRIM(co.extras)) NOT IN ('null', ' ')
) AS extra_toppings
-- Subquery to extract individual topping IDs from the 'extras' column in customer_orders.
-- 'extras' contains a comma-separated string of topping IDs (e.g., '1,2,3').
-- STRING_SPLIT breaks this into rows.
-- TRIM(value) removes any leading/trailing spaces from each split value.
-- The WHERE clause filters out:
--   - NULL values
--   - Strings like 'null' or blank spaces, which may appear due to inconsistent data entry.

JOIN [pizza_runner].[pizza_toppings] pt 
  ON pt.topping_id = extra_toppings.topping_id
-- Joins each extracted topping_id to its corresponding name in the pizza_toppings table.

GROUP BY topping_name
-- Groups the results by topping name to count how many times each topping was added as an extra.

ORDER BY extra_count DESC
-- Sorts the toppings by popularity, showing the most frequently added extras first.

-- 3) What was the most common exclusion?

-- Similar logic to the previous query for extras, but applied to exclusions.
SELECT topping_name, COUNT(*) AS exclusion_count
FROM (
    SELECT 
        co.exclusions,
        TRIM(value) AS topping_id
    FROM [pizza_runner].[customer_orders] AS co
    CROSS APPLY STRING_SPLIT(co.exclusions, ',')
    WHERE co.exclusions IS NOT NULL 
      AND LTRIM(RTRIM(co.exclusions)) NOT IN ('null', ' ')
) AS excluded_toppings
JOIN [pizza_runner].[pizza_toppings] pt 
  ON pt.topping_id = excluded_toppings.topping_id
GROUP BY topping_name
ORDER BY exclusion_count DESC

-- 4) Generate an order item for each record in the customers_orders table in the format of one of the following:
--    - Meat Lovers
--    - Meat Lovers - Exclude Beef
--    - Meat Lovers - Extra Bacon
--    - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
SELECT 
    co.order_id,
    pn.pizza_name +
    CASE 
        WHEN co.exclusions IS NOT NULL AND LTRIM(RTRIM(co.exclusions)) NOT IN ('null', ' ')
        THEN ' - Exclude ' + co.exclusions
        ELSE ''
    END +
    CASE 
        WHEN co.extras IS NOT NULL AND LTRIM(RTRIM(co.extras)) NOT IN ('null', ' ')
        THEN ' - Extra ' + co.extras
        ELSE ''
    END AS order_item
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner].[pizza_names] pn
    ON co.pizza_id = pn.pizza_id
ORDER BY co.order_id;
-- Explanation:
-- This query constructs a descriptive order item for each record in the customer_orders table.
-- It starts with the pizza name from the pizza_names table.
-- It then appends exclusion and extra information conditionally:
-- 1. If there are exclusions, it adds " - Exclude " followed by the exclusions.
-- 2. If there are extras, it adds " - Extra " followed by the extras.
-- The final result is a formatted string that summarizes the pizza order with any modifications.

-- 5) Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table
--    and add a 2x in front of any relevant ingredients (e.g., "Meat Lovers: 2xBacon, Beef, ... , Salami").
SELECT 
    co.order_id,
    pn.pizza_name + ': ' +
    STRING_AGG(
        CASE 
            WHEN et.topping_id IS NOT NULL THEN '2x' + pt.topping_name
            ELSE pt.topping_name
        END,
        ', '
        ) WITHIN GROUP (ORDER BY pt.topping_name) AS ingredient_list
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner].[pizza_names] pn
    ON co.pizza_id = pn.pizza_id
JOIN [pizza_runner].[pizza_recipes] pr
    ON co.pizza_id = pr.pizza_id
JOIN [pizza_runner].[pizza_toppings] pt
    ON CAST(pt.topping_id AS VARCHAR) 
       IN (
           SELECT TRIM(value) 
           FROM STRING_SPLIT(pr.toppings, ',')
       )
LEFT JOIN (
    SELECT
        co.order_id,
        TRIM(value) AS topping_id
    FROM [pizza_runner].[customer_orders] AS co
    CROSS APPLY STRING_SPLIT(co.extras, ',')
    WHERE co.extras IS NOT NULL 
      AND LTRIM(RTRIM(co.extras)) NOT IN ('null', ' ')
) AS et
    ON co.order_id = et.order_id AND pt.topping_id = et.topping_id
GROUP BY co.order_id, pn.pizza_name
ORDER BY co.order_id;
-- Explanation:
-- This query generates a detailed ingredient list for each pizza order in the customer_orders table.
-- It starts by joining the necessary tables to get pizza names, recipes, and toppings.
-- It uses STRING_AGG to concatenate the ingredient names into a single comma-separated string.
-- The CASE statement checks if a topping was added as an extra (from the left join with et):
--   - If it was an extra, it prefixes the topping name with '2x'.
--   - Otherwise, it just includes the topping name.


-- 6) What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH DeliveredPizzas AS (
    SELECT 
        co.order_id,
        co.pizza_id
    FROM [pizza_runner].[customer_orders] co
    JOIN [pizza_runner].[runner_orders] ro
        ON co.order_id = ro.order_id
    WHERE ro.pickup_time != 'null' -- Exclude cancelled orders
), PizzaIngredients AS (
    SELECT 
        dp.order_id,
        pt.topping_id
    FROM DeliveredPizzas dp
    JOIN [pizza_runner].[pizza_recipes] pr
        ON dp.pizza_id = pr.pizza_id
    JOIN [pizza_runner].[pizza_toppings] pt
        ON CAST(pt.topping_id AS VARCHAR) 
           IN (
               SELECT TRIM(value) 
               FROM STRING_SPLIT(pr.toppings, ',')
           )
)
SELECT 
    pt.topping_name,
    COUNT(pi.topping_id) AS total_quantity
FROM PizzaIngredients pi
JOIN [pizza_runner].[pizza_toppings] pt
    ON pi.topping_id = pt.topping_id
GROUP BY pt.topping_name
ORDER BY total_quantity DESC;
-- Explanation:
-- The CTE DeliveredPizzas filters the customer_orders to include only those that were successfully delivered (i.e., have a valid pickup_time).
-- The CTE PizzaIngredients then joins these delivered pizzas with their respective ingredients based on the pizza_recipes.
-- The main query counts the occurrences of each topping across all delivered pizzas and orders the results by  total quantity in descending order.     


-- D. Pricing and Ratings
-- 1) If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes,
--    how much money has Pizza Runner made so far if there are no delivery fees?

SELECT 
    SUM(
        CASE 
            WHEN pn.pizza_name = 'Meatlovers' THEN 12
            WHEN pn.pizza_name = 'Vegetarian' THEN 10
            ELSE 0
        END
    ) AS total_revenue
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner].[pizza_names] pn
    ON co.pizza_id = pn.pizza_id
JOIN [pizza_runner].[runner_orders] ro
    ON co.order_id = ro.order_id
WHERE ro.pickup_time != 'null'; -- Exclude cancelled orders
-- Explanation:
-- This query calculates the total revenue generated by Pizza Runner from delivered pizzas.
-- It joins the customer_orders with pizza_names to get the pizza names and their corresponding prices.
-- It also joins with runner_orders to filter out any cancelled orders (where pickup_time is 'null').
-- The CASE statement assigns the price based on the pizza name, summing up the total revenue
-- from all successfully delivered pizzas.


-- 2) What if there was an additional $1 charge for any pizza extras? (Add cheese is $1 extra)
SELECT 
    SUM(
        CASE 
            WHEN pn.pizza_name = 'Meatlovers' THEN 12
            WHEN pn.pizza_name = 'Vegetarian' THEN 10
            ELSE 0
        END +
        CASE 
            WHEN co.extras IS NOT NULL AND LTRIM(RTRIM(co.extras)) NOT IN ('null', ' ')
            THEN 1
            ELSE 0
        END
    ) AS total_revenue_with_extras  
FROM [pizza_runner].[customer_orders] co
JOIN [pizza_runner].[pizza_names] pn
    ON co.pizza_id = pn.pizza_id
JOIN [pizza_runner].[runner_orders] ro
    ON co.order_id = ro.order_id
WHERE ro.pickup_time != 'null'; -- Exclude cancelled orders
-- Explanation:
-- This query calculates the total revenue generated by Pizza Runner from delivered pizzas, including an additional charge
-- for any extras.
-- It joins the customer_orders with pizza_names to get the pizza names and their corresponding prices.
-- It also joins with runner_orders to filter out any cancelled orders (where pickup_time is 'null').
-- The first CASE statement assigns the base price based on the pizza name.
-- The second CASE statement adds $1 to the price if there are any extras for the pizza.
-- The total revenue is then summed up from all successfully delivered pizzas.

-- 3) The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner.
--    Design a table schema and insert ratings (1–5) for each successful customer order.
DROP TABLE IF EXISTS customer_ratings;
CREATE TABLE customer_ratings (
    "order_id" INTEGER,
    "customer_id" INTEGER,
    "runner_id" INTEGER,
    "rating" INTEGER
    );
INSERT INTO customer_ratings
    ("order_id", "customer_id", "runner_id", "rating")
VALUES
    (1, 1, 1, 5),
    (2, 1, 1, 4),
    (3, 1, 1, 5),
    (4, 2, 2, 3),
    (5, 3, 3, 4),
    (7, 2, 2, 2),
    (8, 2, 2, 4),
    (10, 1, 1, 5);
-- Explanation:
-- The customer_ratings table is designed to store ratings given by customers for their runners.
-- It includes the following columns:
-- 1. order_id: The unique identifier for the order.
-- 2. customer_id: The unique identifier for the customer who placed the order.
-- 3. runner_id: The unique identifier for the runner who delivered the order.
-- 4. rating: An integer value representing the customer's rating of the runner (1 to 5).
-- Ratings are only inserted for successful customer orders (i.e., those with a valid pickup_time).


-- 4) Using the newly generated table, join all information for successful deliveries to produce:
--    customer_id, order_id, runner_id, rating, order_time, pickup_time, time between order and pickup,
--    delivery duration, average speed, total number of pizzas.
SELECT 
    cr.customer_id,
    cr.order_id,
    cr.runner_id,
    cr.rating,
    co.order_time,
    ro.pickup_time,
    DATEDIFF(minute, co.order_time, ro.pickup_time) AS time_between_order_and_pickup,
    ro.duration,
    (CAST(REPLACE(trim(ro.distance), 'km', '') AS FLOAT) / 
     CAST(REPLACE(
        TRANSLATE(
            ro.duration,
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
            '                                                    ' -- 52 spaces
        ),
        ' ',
        '') AS FLOAT)) * 60 AS average_speed_kmh,
    COUNT(co.pizza_id) AS total_number_of_pizzas
FROM customer_ratings cr
JOIN pizza_runner.customer_orders co
    ON cr.order_id = co.order_id
JOIN pizza_runner.runner_orders ro
    ON cr.order_id = ro.order_id
WHERE ro.pickup_time != 'null' -- Exclude cancelled orders
GROUP BY 
    cr.customer_id,
    cr.order_id,
    cr.runner_id,
    cr.rating,
    co.order_time,
    ro.pickup_time,
    ro.duration,
    ro.distance;
-- Explanation:
-- This query retrieves detailed information about successful deliveries by joining the customer_ratings,
-- customer_orders, and runner_orders tables.   
-- It selects the customer_id, order_id, runner_id, rating, order_time, and pickup_time.
-- It calculates the time between order and pickup using DATEDIFF.
-- It also calculates the average speed in km/h by dividing the distance by the duration (converted to hours).
-- Finally, it counts the total number of pizzas in each order.
-- The WHERE clause filters out any cancelled orders (where pickup_time is 'null').

-- 5) If Meat Lovers is $12 and Vegetarian $10 (no cost for extras) and runners are paid $0.30/km,
--    how much money does Pizza Runner have left after these deliveries?
WITH DeliveryCosts AS (
    SELECT 
        co.order_id,
        SUM(
            CASE 
                WHEN pn.pizza_name = 'Meatlovers' THEN 12
                WHEN pn.pizza_name = 'Vegetarian' THEN 10
                ELSE 0
            END
        ) AS order_revenue,
        SUM(
            CAST(REPLACE(trim(ro.distance), 'km', '') AS FLOAT) * 0.30
        ) AS runner_payment
    FROM pizza_runner.customer_orders co
    JOIN pizza_runner.pizza_names pn
        ON co.pizza_id = pn.pizza_id
    JOIN pizza_runner.runner_orders ro
        ON co.order_id = ro.order_id
    WHERE ro.pickup_time != 'null' -- Exclude cancelled orders
    GROUP BY co.order_id
)
SELECT 
    SUM(order_revenue) - SUM(runner_payment) AS total_profit
FROM DeliveryCosts;
-- Explanation:
-- The CTE DeliveryCosts calculates the revenue from each order and the payment to runners based on
-- the distance traveled.
-- It joins the customer_orders with pizza_names to get the pizza prices and with runner_orders to get the distances.
-- The main query then calculates the total profit by subtracting the total runner payments from the total order revenue.


-- E. Bonus Questions
-- 1) If Danny adds more pizzas, how does this impact the data design?
--    Answer:
--    Adding more pizzas would require updating the pizza_names and pizza_recipes tables to include the
--    new pizza types and their respective ingredients. The customer_orders table would also need to
--    accommodate orders for the new pizzas. The existing schema is designed to be flexible, allowing
--    for easy addition of new pizza types without significant changes to the overall structure.
--   2) Write an INSERT to add a new 'Supreme' pizza with all toppings to the menu.
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (3, 'Supreme');
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (3, (SELECT STRING_AGG(CAST(topping_id AS VARCHAR), ',')
       FROM pizza_runner.pizza_toppings));

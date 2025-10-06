# Case Study Danny's Dinner
<img width="1080" height="1080" alt="image" src="https://github.com/user-attachments/assets/341109b3-7ac8-44ce-80e1-83da6519a2e1" />

### **Business Task**
Danny aims to leverage customer data to gain valuable insights into customer behavior, spending patterns, and menu item preferences. This analysis will enable him to enhance the personalized experience for his loyal customers and make informed decisions regarding the expansion of his existing customer loyalty.

### Database Relationship Diagram

<img width="840" height="533" alt="relationship" src="https://github.com/user-attachments/assets/e0467ff4-01e6-481c-9fed-841990c8da13" />

All dataset are within dannys_dinner schema which includes:
- sales: The sales table captures all customer_id level purchases with an corresponding order_date and product_id information for when and what menu items were ordered.
- menu: The menu table maps the product_id to the actual product_name and price of each menu item.
- members: The members table captures the join_date when a customer_id joined the beta version of the Danny’s Diner loyalty program.

Use https://www.db-fiddle.com/ to run [query](https://github.com/gleidyalonzo/8-Week-SQL-Challenge/blob/main/Case%201_%20Danny's%20Dinner/case1.sql)

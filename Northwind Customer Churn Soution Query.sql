#                                                           Purchase Frequency:
/*
Question 1: Identify trends in order frequency over time. Are there customers whose purchase frequency sharply declines before churn?

We can analyze the order frequency for each customer over time and identify any patterns where the purchase frequency sharply 
declines before churn. This can be done by calculating the time gap between consecutive orders for each customer and observing 
any significant changes in this gap before they stop making purchases.
*/
WITH OrderFrequency AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date,
        DATEDIFF(order_date, LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)) AS time_gap
    FROM Orders
)
SELECT 
    customer_id,
    AVG(time_gap) AS average_time_gap
FROM OrderFrequency
GROUP BY customer_id
order by average_time_gap desc;

/*
This query calculates the average time gap between consecutive orders for each customer. We can then analyze this data to identify 
customers whose purchase frequency sharply declines before churn.
*/




/*
Question 2: Calculate metrics like average time between orders for different customer segments (e.g., frequent vs. infrequent buyers).

To calculate metrics like the average time between orders for different customer segments, we can classify customers into segments 
based on their order frequency (e.g., frequent buyers, infrequent buyers) and then calculate the average time between orders for 
each segment.

*/

WITH OrderFrequency AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date,
        DATEDIFF(order_date, LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)) AS time_gap
    FROM Orders
),
CustomerSegments AS (
    SELECT 
        customer_id,
        CASE 
            WHEN AVG(time_gap) <= 30 THEN 'Frequent Buyer'
            WHEN AVG(time_gap) <= 90 THEN 'Regular Buyer'
            ELSE 'Infrequent Buyer'
        END AS segment
    FROM OrderFrequency
    GROUP BY customer_id
)
SELECT 
    segment,
    AVG(time_gap) AS average_time_gap
FROM OrderFrequency o
JOIN CustomerSegments cs ON o.customer_id = cs.customer_id
GROUP BY segment
ORDER BY average_time_gap;

/*
This query classifies customers into segments based on their average time gap between orders and calculates the average time gap
 for each segment. It categorizes customers as frequent, regular, or infrequent buyers based on their purchase frequency.
*/





#                                                               Order Size:

/*
Question 3: Analyze average order value for churning and non-churning customers. Do customers typically reduce their order 
size before churning?

We'll compare the average order value between churning and non-churning customers to see if there's a noticeable difference 
and whether customers tend to reduce their order size before churning.
*/

WITH ChurnStatus AS (
    SELECT
        c.id,
        CASE
            WHEN o.customer_id IS NOT NULL THEN 'Non-Churning'
            ELSE 'Churning'
        END AS churn_status
    FROM Customers c
    LEFT JOIN Orders o ON c.id = o.customer_id
),
OrderValue AS (
    SELECT
        o.customer_id,
        SUM(od.quantity * od.unit_price) AS order_value
    FROM Orders o
    JOIN Order_Details od ON o.id = od.order_id
    GROUP BY o.customer_id
)
SELECT
    cs.churn_status,
    AVG(ov.order_value) AS avg_order_value
FROM ChurnStatus cs
JOIN OrderValue ov ON cs.id = ov.customer_id
GROUP BY cs.churn_status;

/*
This query compares the average order value between churning and non-churning customers. By analyzing the results, we can determine 
if there's a noticeable difference in order size before churning.
*/





/*
Question 4: Explore the distribution of order value. Are there customer groups consistently placing smaller orders, potentially 
indicating a higher churn risk?

/*
We'll explore the distribution of order values across different customer groups to identify if there are consistent patterns of 
smaller orders, which could indicate a higher churn risk.
*/

WITH OrderValueDistribution AS (
    SELECT
        c.id,
        SUM(od.quantity * od.unit_price) AS order_value
    FROM Customers c
    LEFT JOIN Orders o ON c.id = o.customer_id
    LEFT JOIN Order_Details od ON o.id = od.order_id
    GROUP BY c.id
)
SELECT
    CASE
        WHEN order_value >= 5000 THEN 'High Order Value'
        WHEN order_value >= 1000 THEN 'Medium Order Value'
        ELSE 'Low Order Value'
    END AS order_value_category,
    COUNT(id) AS customer_count
FROM OrderValueDistribution
GROUP BY order_value_category
ORDER BY customer_count DESC;

/*
This query categorizes customers based on the total value of their orders and counts the number of customers falling into different 
order value categories. By analyzing the distribution, we can identify if there are consistent groups of customers placing smaller 
orders, indicating a potentially higher churn risk.
*/






/*
Question 5: Analyze the most frequently purchased categories before and after churn events. Did their buying habits shift towards 
different product lines?
*/

/*
To analyze the most frequently purchased categories before and after churn events and determine if there's a shift in buying habits 
towards different product lines, we need to compare the frequency of purchases in each category for churned customers and 
active customers.
*/

WITH churned_customers AS (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE status_id = 3
)
SELECT p.category,
       COUNT(CASE WHEN o.customer_id IN (SELECT customer_id FROM churned_customers) THEN o.id END) AS churned_count,
       COUNT(CASE WHEN o.customer_id NOT IN (SELECT customer_id FROM churned_customers) THEN o.id END) AS active_count
FROM orders o
JOIN order_details od ON o.id = od.order_id
JOIN products p ON od.product_id = p.id
GROUP BY p.category
ORDER BY churned_count DESC;





#                                                     Geographical Insights:

/*
Question 6: Leverage customer location data (if available) to investigate churn rates by region. Are there specific locations with 
higher churn?
*/

# To investigate churn rates by region and explore correlations between location and purchase behavior, we can use SQL to analyze 
# customer data based on their geographical information.


WITH churned_customers AS (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE status_id IN (
        SELECT id FROM orders_status WHERE status_name = 'Closed' OR status_name = 'Shipped'
    )
),
customer_locations AS (
    SELECT c.id,
           c.company,
           c.city,
           c.state_province,
           c.country_region,
           CASE WHEN cc.customer_id IS NOT NULL THEN 'Churned' ELSE 'Active' END AS customer_status
    FROM customers c
    LEFT JOIN churned_customers cc ON c.id = cc.customer_id
)
SELECT country_region,
       state_province,
       city,
       COUNT(CASE WHEN customer_status = 'Churned' THEN 1 END) AS churned_count,
       COUNT(CASE WHEN customer_status = 'Active' THEN 1 END) AS active_count,
       ROUND((COUNT(CASE WHEN customer_status = 'Churned' THEN 1 END) * 100.0) / COUNT(*), 2) AS churn_rate
FROM customer_locations
GROUP BY country_region, state_province, city
ORDER BY churn_rate DESC;

/*
The churned customers are identified based on the closed or shipped status of their orders, as these could indicate that the customer 
has churned.This query calculates the churn rates by region (country, state/province, city) based on the number of churned and active 
customers.
*/





/*
Question 7: Explore correlations between location and purchase behavior. Do buying patterns differ significantly across regions?
*/

SELECT 
    c.country_region,
    c.state_province,
    c.city,
    COUNT(o.id) AS total_orders,
    ROUND(SUM(od.quantity)) AS total_quantity,
    ROUND(SUM(od.quantity * od.unit_price)) AS total_revenue
FROM 
    customers c
JOIN 
    orders o ON c.id = o.customer_id
JOIN 
    order_details od ON o.id = od.order_id
GROUP BY 
    c.country_region, c.state_province, c.city
ORDER BY 
    c.country_region, c.state_province, c.city;
    
/*
This query retrieves the total number of orders, total quantity purchased, and total revenue generated for each region 
(country, state, city). It joins the customers, orders, and order_details tables to gather this information. By analyzing the 
output of this query, you can identify any significant differences in buying patterns across different regions.
*/






#                                                              Marketing Strategies:

/*
Question 8: Personalized Campaigns: 
Design targeted marketing campaigns based on customer purchase behavior and product preferences. 
Offer incentives to re-engage customers at risk of churn.
*/

-- Step 1 - We can Identify customers at risk of churn.

SELECT 
    c.id,
    COUNT(o.id) AS TotalOrders,
    SUM(od.unit_price * od.Quantity) AS TotalSpent
FROM 
    Customers c
LEFT JOIN 
    Orders o ON c.id = o.Customer_ID
LEFT JOIN 
    Order_Details od ON o.id = od.Order_ID
GROUP BY 
    c.id
HAVING 
    TotalOrders >= 7 AND TotalSpent >= 1000;

-- Step 2 - We can go for targeted marketing campaigns based on customer purchase behavior and product preferences.
-- Example: Offer discounts on frequently purchased products
SELECT 
    c.id,
    p.Product_Name,
    COUNT(od.order_id) AS Purchases
FROM 
    Customers c
JOIN 
    Orders o ON c.id = o.Customer_ID
JOIN 
    order_details od ON o.id = od.order_id
JOIN 
    Products p ON od.product_id = p.id
GROUP BY 
    c.id, p.Product_Name
ORDER BY 
    Purchases DESC;

/*
In the first query, it identifies customers who have made at least 7 orders and spent over $1000 in total, indicating a higher likelihood 
of churn.
In the second query, it provides insights into customer purchase behavior by listing the products they purchase most frequently, 
enabling the design of targeted marketing campaigns such as offering discounts on these products to encourage continued engagement.
*/





/*
Question 9: Loyalty Programs: 
Develop loyalty programs or rewards specifically for customers exhibiting churn risk to encourage continued engagement.
*/

-- Identify customers at risk of churn
SELECT 
    c.id,
    COUNT(o.id) AS TotalOrders,
    SUM(od.Unit_Price * od.Quantity) AS TotalSpent
FROM 
    Customers c
LEFT JOIN 
    Orders o ON c.id = o.Customer_ID
LEFT JOIN 
    Order_Details od ON o.id = od.Order_ID
GROUP BY 
    c.id
HAVING 
    TotalOrders >= 7 AND TotalSpent >= 1000;


    


-- Develop loyalty programs or rewards specifically for customers exhibiting churn risk
-- Example: Offer loyalty points or discounts on future purchases
SELECT 
    c.id,
    COALESCE(SUM(od.Unit_Price * od.Quantity), 0) AS TotalSpent,
    CASE 
        WHEN COUNT(o.id) >= 7 AND SUM(od.Unit_Price * od.Quantity) >= 1000 THEN 'Gold'
        ELSE 'Silver'
    END AS LoyaltyTier
FROM 
    Customers c
LEFT JOIN 
    Orders o ON c.id = o.Customer_ID
LEFT JOIN 
    Order_Details od ON o.id = od.Order_ID
GROUP BY 
    c.id;

/*
These queries first identify customers at risk of churn based on their order frequency and total spending. Then, they assign loyalty 
tiers (Gold or Silver) to these customers, allowing for the development of targeted loyalty programs or rewards.
*/





#                                            Customer Experience Improvements:


/*
Question 10: Identify Pain Points: Analyze the reasons behind changing purchase patterns. Are there customer service issues or product 
quality concerns that need addressing?
*/


-- Identify potential pain points and reasons behind changing purchase patterns
SELECT 
    c.id AS customer_id,
    c.company AS company_name,
    o.id AS order_id,
    o.order_date,
    od.product_id,
    p.product_name,
    od.quantity,
    od.unit_price,
    od.quantity * od.unit_price AS total_price,
    o.ship_city AS delivery_city,
    o.ship_country_region AS delivery_country,
    CASE
        WHEN od.quantity * od.unit_price = 0 THEN 'Free Item'
        WHEN od.quantity * od.unit_price < 10 THEN 'Low Value'
        ELSE 'High Value'
    END AS purchase_category,
    CASE
        WHEN od.quantity * od.unit_price = 0 THEN 'Product Unavailable'
        WHEN p.discontinued = 1 THEN 'Discontinued Product'
        ELSE 'Quality Issue'
    END AS reason_for_change
FROM 
    orders o
JOIN 
    order_details od ON o.id = od.order_id
JOIN 
    products p ON od.product_id = p.id
JOIN 
    customers c ON o.customer_id = c.id
WHERE
    o.shipped_date IS NOT NULL
ORDER BY 
    o.order_date DESC;

/*
Above query retrieves data about recent orders, including customer information, order details, product information, delivery location, 
and reasons for any changes in purchase patterns. It categorizes purchases based on value and identifies potential reasons for changes, 
such as product unavailability, discontinued products, or quality issues.

We can customize this query based on the specific structure of database and the information available to us regarding customer feedback, 
product quality, and service issues.
*/






#                                          Executive Summary: The Churn Narrative

#	Question 11:Briefly explain the problem of customer churn and its impact on Northwind.

SELECT 
    COUNT(DISTINCT c.id) AS TotalCustomers,
    COUNT(DISTINCT CASE WHEN o.customer_id IS NULL THEN c.id END) AS ChurnedCustomers,
    ROUND((COUNT(DISTINCT CASE WHEN o.customer_id IS NULL THEN c.id END) / COUNT(DISTINCT c.id)) * 100, 2) AS ChurnRate
FROM 
    customers c
LEFT JOIN 
    orders o ON c.id = o.customer_id;


/*
This query calculates the total number of customers, the number of churned customers (those who have not placed any orders), and the 
churn rate as a percentage of total customers. It provides a clearer picture of the churn problem by considering only the customers 
who have not placed any orders as churned customers.
*/



#	Question 12:Describe the key customer behavior patterns you discovered that are linked to churn.

SELECT 
    c.id,
    COUNT(o.id) AS TotalOrders,
    SUM(od.unit_price * od.quantity) AS TotalSpent
FROM 
    customers c
LEFT JOIN 
    orders o ON c.id = o.customer_id
LEFT JOIN 
    order_details od ON o.id = od.order_id
GROUP BY 
    c.id
HAVING 
    TotalOrders >= 7 AND TotalSpent >= 1000;
    
/*
By executing this query, we can identify customers who exhibit certain behavior patterns, such as making a relatively high number of 
orders and spending a substantial amount, which may indicate loyalty and engagement. These insights can help Northwind understand 
which customers are less likely to churn and tailor retention strategies accordingly.
*/




# Question 13:Present your churn prediction model and customer segmentation strategy.


SELECT 
    c.id,
    COALESCE(SUM(od.Unit_Price * od.Quantity), 0) AS TotalSpent,
    CASE 
        WHEN COUNT(o.id) >= 7 AND SUM(od.Unit_Price * od.Quantity) >= 1000 THEN 'Gold'
        ELSE 'Silver'
    END AS LoyaltyTier
FROM 
    Customers c
LEFT JOIN 
    Orders o ON c.id = o.Customer_ID
LEFT JOIN 
    Order_Details od ON o.id = od.Order_ID
GROUP BY 
    c.id;

/*
This segmentation strategy allows Northwind to categorize customers based on their spending behavior, providing insights for targeted 
marketing campaigns, loyalty programs, and personalized customer experiences. Customers falling into the "Gold" category may receive 
special offers or VIP treatment, while those in the "Silver" category may be targeted with incentives to increase spending and loyalty.

*/





#	Question 14:Conclude with actionable recommendations for Northwind, like targeted marketing campaigns or improved customer service, 
#	all based on your data analysis.
    
SELECT 
    c.id,
    COALESCE(AVG(o.shipping_fee), 0) AS AvgShippingFee,
    COALESCE(AVG(o.taxes), 0) AS AvgTaxes,
    COUNT(DISTINCT o.order_date) AS TotalOrders,
    COALESCE(SUM(od.Unit_Price * od.Quantity), 0) AS TotalSpent,
    CASE 
        WHEN COUNT(DISTINCT o.order_date) >= 5 AND SUM(od.Unit_Price * od.Quantity) >= 1000 THEN 'Gold'
        ELSE 'Silver'
    END AS LoyaltyTier
FROM 
    Customers c
LEFT JOIN 
    Orders o ON c.id = o.Customer_ID
LEFT JOIN 
    Order_Details od ON o.id = od.Order_ID
GROUP BY 
    c.id;

/*
This query provides insights into customer spending habits, order frequency, and loyalty tiers, which can be valuable for targeted 
marketing campaigns, customer segmentation, and improving overall customer satisfaction and retention strategies at Northwind Traders.
*/




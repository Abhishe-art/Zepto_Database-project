
USE zepto_database;

-- Data cleaning

ALTER TABLE zepto
RENAME COLUMN ï»¿Category TO category;

UPDATE zepto
SET category = TRIM(category);


SELECT * FROM  zepto 
WHERE mrp =0 
AND discountPercent =0;

DELETE 
FROM zepto
WHERE mrp = 0
AND discountPercent = 0;

SELECT *,
ROW_NUMBER () OVER (
PARTITION BY category,name,mrp,discountPercent,availableQuantity,discountedSellingPrice,weightInGms,outOfStock,quantity)
FROM zepto;


WITH Duplicate_cte AS 
(
SELECT *,
ROW_NUMBER () OVER (
PARTITION BY category,name,mrp,discountPercent,availableQuantity,discountedSellingPrice,weightInGms,outOfStock,quantity) Row_num
FROM zepto
)
SELECT *
FROM Duplicate_cte
WHERE Row_num >1;

CREATE TABLE zepto_clean AS
WITH CTE_duplicates AS(
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY category,
        name,
        mrp,
        discountPercent,
        availableQuantity,
        discountedSellingPrice,
        weightInGms,
        outOfStock,
        quantity
			ORDER BY name
)AS row_num
FROM zepto
)
SELECT *
FROM CTE_duplicates 
WHERE row_num =1;

SELECT * FROM zepto_clean;

ALTER TABLE zepto_clean
ADD COLUMN Sku_id int
auto_increment Primary key first;

ALTER TABLE zepto_clean
DROp COLUMN row_num;

SELECT * FROM zepto_clean
WHERE mrp =0 OR discountedSellingPrice =0;


CREATE TABLE `zepto2` (
  `Sku_id` int NOT NULL AUTO_INCREMENT,
  `category` text,
  `name` text,
  `mrp` int DEFAULT NULL,
  `discountPercent` int DEFAULT NULL,
  `availableQuantity` int DEFAULT NULL,
  `discountedSellingPrice` int DEFAULT NULL,
  `weightInGms` int DEFAULT NULL,
  `outOfStock` text,
  `quantity` int DEFAULT NULL,
  PRIMARY KEY (`Sku_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3726 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Create duplicate table

SELECT * FROM zepto2;

INSERT INTO zepto2
SELECT * FROM zepto_clean;


UPDATE zepto2
SET mrp = mrp/100.0 ,
discountedSellingPrice = discountedSellingPrice/100.0;

SELECT mrp,discountedSellingPrice FROM zepto2;


-- Quaries 


START TRANSACTION;

-- 1. Find the top 10 best-value products based on the discount percentage.

SELECT DISTINCT name,mrp,discountpercent
FROM zepto2
ORDER BY discountpercent DESC
LIMiT 10;


-- 2. What are the products with high MRP but out of stock?

SELECT DISTINCT name,mrp
FROM zepto2
WHERE outOfStock = 'TRUE' AND mrp > 300
ORDER BY mrp DESC;

-- 3. Calculate estimated revenue for each category.

SELECT category,
SUM(discountedSellingPrice *availableQuantity) AS revenue
FROM zepto2
GROUP BY category
ORDER BY revenue;

-- 4. Find all products where MRP is greater than ₹500 and discount is less than 10%.

SELECT name,mrp
FROM zepto2
WHERE mrp >500 AND discountpercent <10
ORDER BY mrp DESC , discountpercent DESC;


-- 5. Identify the top 5 categories offering the highest average discount percentage.

SELECT category ,Avg(discountpercent) avg_discount
FROM zepto2
GROUP BY category 
ORDER BY avg_discount DESC
LIMIT 5;


SELECT category ,ROUND(Avg(discountpercent),2) avg_discount
FROM zepto2
GROUP BY category 
ORDER BY avg_discount DESC
LIMIT 5;

-- 6. Find the price per gram for products above 100g and sort by best value.

SELECT DISTINCT name,weightInGms,discountedSellingPrice,
round(discountedSellingPrice/weightInGms,2) AS price_per_gms
FROM zepto2
WHERE weightIngms >= 100
Order BY price_per_gms;

-- 7. Group the products into categories like Low, Medium, Bulk.

SELECT DISTINCT name,weightInGms,
CASE 
	WHEN weightIngms < 1000 THEN'Low'
    WHEN weightInGms BETWEEN 1000 AND 5000 THEN 'medium'
    WHEN weightINgms >5000 THEN 'Bulk'
END weight_category
FROM zepto2;


-- 8. What is the total inventory weight per category?
 
SELECT category
,SUM(weightInGms * availableQuantity) AS Total_weight
FROM zepto2
GROUP BY category
ORDER BY Total_weight DESC;


commit;





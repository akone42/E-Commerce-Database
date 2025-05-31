-- Active: 1746255433403@@127.0.0.1@3306
-- # Put all of your SQL here

-- SET FOREIGN_KEY_CHECKS = 0;
-- DROP TABLE IF EXISTS country;
CREATE TABLE country (
    country_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    country VARCHAR(255) NOT NULL,
    INDEX idx_country_name (country)
);
-- SET FOREIGN_KEY_CHECKS = 1;


-- SET FOREIGN_KEY_CHECKS = 0;
-- DROP TABLE IF EXISTS city;
CREATE TABLE city (
    city_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    city VARCHAR(255) NOT NULL,
    country_id INT UNSIGNED NOT NULL,
    UNIQUE (city, country_id),
    FOREIGN KEY (country_id) REFERENCES country(country_id)
);
-- SET FOREIGN_KEY_CHECKS = 1;


-- SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS seller;
CREATE TABLE seller (
    seller_id INT UNSIGNED PRIMARY KEY,
    seller_name VARCHAR(255) NOT NULL,
    seller_country INT UNSIGNED NOT NULL,
    INDEX idx_seller_name (seller_name),
    FOREIGN KEY (seller_country) REFERENCES country(country_id)
);
-- SET FOREIGN_KEY_CHECKS = 1;


-- SET FOREIGN_KEY_CHECKS = 0;
-- DROP TABLE IF EXISTS buyer;
CREATE TABLE buyer (
    buyer_id INT UNSIGNED PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    address VARCHAR(255) NOT NULL,       
    city_id INT UNSIGNED NOT NULL,        
    INDEX idx_buyer_name (first_name, last_name),
    FOREIGN KEY (city_id) REFERENCES city(city_id)
);
-- SET FOREIGN_KEY_CHECKS = 1;

-- SET FOREIGN_KEY_CHECKS = 0;
-- DROP TABLE IF EXISTS product;

CREATE TABLE product (
    product_id INT UNSIGNED  PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    product_price INT NOT NULL,
    seller_id INT UNSIGNED NOT NULL,
    FOREIGN KEY (seller_id) REFERENCES seller(seller_id)
);
-- SET FOREIGN_KEY_CHECKS = 1;



-- SET FOREIGN_KEY_CHECKS = 0;
-- DROP TABLE IF EXISTS credit_card;
CREATE TABLE credit_card (
    cc_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cc_number VARCHAR(256) NOT NULL,
    cc_exp VARCHAR(7) NOT NULL,
    buyer_id INT UNSIGNED NOT NULL,
    UNIQUE (buyer_id, cc_number),
    FOREIGN KEY (buyer_id) REFERENCES buyer(buyer_id)
);
-- SET FOREIGN_KEY_CHECKS = 1;

-- SET FOREIGN_KEY_CHECKS = 0;
-- DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id INT UNSIGNED  PRIMARY KEY,
    order_quantity INT UNSIGNED NOT NULL,
    order_date DATE NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    buyer_id INT UNSIGNED NOT NULL,
    cc_id INT UNSIGNED NOT NULL,
    INDEX idx_orders_date (order_date),
    FOREIGN KEY (product_id) REFERENCES product(product_id),
    FOREIGN KEY (buyer_id) REFERENCES buyer(buyer_id),
    FOREIGN KEY (cc_id) REFERENCES credit_card(cc_id)
);
-- SET FOREIGN_KEY_CHECKS = 1;

-- SET FOREIGN_KEY_CHECKS = 0;
-- DROP TABLE IF EXISTS reviews;
CREATE TABLE reviews (
    review_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id INT UNSIGNED NOT NULL,
    review TEXT NOT NULL,
    rating INT UNSIGNED NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    INDEX idx_reviews_rating (rating)
);
-- SET FOREIGN_KEY_CHECKS = 1;

DELIMITER $$

CREATE PROCEDURE top_ten_for_country(IN in_country VARCHAR(255))
BEGIN
    SELECT 
        buyer.buyer_id AS buyer_id, 
        buyer.first_name AS first_name, 
        buyer.last_name AS last_name,
        CONCAT('$', FORMAT(SUM(product.product_price * orders.order_quantity) / 100, 2)) AS total_amount_spent
    FROM buyer
    JOIN orders ON buyer.buyer_id = orders.buyer_id
    JOIN product ON orders.product_id = product.product_id
    JOIN city ON buyer.city_id = city.city_id
    JOIN country ON city.country_id = country.country_id
    WHERE country.country = in_country
    GROUP BY buyer.buyer_id
    ORDER BY SUM(product.product_price * orders.order_quantity) DESC
    LIMIT 10;
END $$

DELIMITER ;

CREATE VIEW top_rated_products AS
SELECT 
    product.product_id AS product_id,
    product.product_name AS product_name,  
    CONCAT('$', FORMAT(product.product_price/100, 2)) AS product_price, 
    AVG(reviews.rating) AS avg_rating, 
    COUNT(reviews.rating) AS rating_count
FROM product
JOIN orders ON product.product_id = orders.product_id
JOIN reviews ON reviews.order_id = orders.order_id
GROUP BY product.product_id, product.product_name
HAVING COUNT(reviews.rating) >= 20
ORDER BY avg_rating DESC
LIMIT 10;

DELIMITER $$

-- SELECT * FROM top_rated_products;


-- EXPLAIN
-- SELECT 
--         orders.order_id AS order_id, 
--         orders.order_quantity AS order_quantity, 
--         product.product_name AS product_name, 
--         orders.order_date AS order_date
--     FROM buyer
--     JOIN orders ON buyer.buyer_id = orders.buyer_id
--     JOIN product ON orders.product_id = product.product_id
--     WHERE buyer.first_name = "Leland" 
--       AND buyer.last_name = "Kilback" 
--       AND orders.order_date = "2019-07-23";
CREATE PROCEDURE buyer_for_date(IN in_first_name VARCHAR(255), IN in_last_name VARCHAR(255), IN in_order_date DATE)
BEGIN
    SELECT 
        orders.order_id AS order_id, 
        orders.order_quantity AS order_quantity, 
        product.product_name AS product_name, 
        orders.order_date AS order_date
    FROM buyer
    JOIN orders ON buyer.buyer_id = orders.buyer_id
    JOIN product ON orders.product_id = product.product_id
    WHERE buyer.first_name = in_first_name 
      AND buyer.last_name = in_last_name 
      AND orders.order_date = in_order_date;
END $$
DELIMITER ;

-- SELECT b.first_name, b.last_name, o.order_date
-- FROM   orders o
-- JOIN   buyer  b ON b.buyer_id = o.buyer_id
-- LIMIT 10;

CREATE VIEW top_five_buyer_cities AS
SELECT 
    city.city AS city,  
    CONCAT('$', FORMAT(SUM(product.product_price * orders.order_quantity) / 100, 2)) AS total_amount_spent
FROM buyer
JOIN orders ON buyer.buyer_id = orders.buyer_id
JOIN product ON product.product_id = orders.product_id
JOIN city ON buyer.city_id = city.city_id
GROUP BY city.city
ORDER BY SUM(product.product_price * orders.order_quantity) DESC
LIMIT 5;


-- DROP PROCEDURE IF EXISTS sales_for_month;
DELIMITER $$

CREATE PROCEDURE sales_for_month(IN in_date DATE)
BEGIN
    SELECT 
        DATE_FORMAT(in_date,'%Y-%m') AS month_and_year, 
        CONCAT('$', FORMAT(SUM(product.product_price * orders.order_quantity) / 100, 2)) AS total_sales
    FROM orders
    JOIN product ON product.product_id = orders.product_id
    WHERE MONTH(order_date) = MONTH(in_date) AND YEAR(order_date) = YEAR(in_date)
    GROUP BY DATE_FORMAT(in_date,'%Y-%m');
END $$

DELIMITER ;


-- DROP VIEW seller_sales_tiers;
CREATE VIEW seller_sales_tiers AS 
SELECT 
    seller.seller_id AS seller_id, 
    seller.seller_name AS seller_name, 
    CONCAT('$', FORMAT(SUM(product.product_price * orders.order_quantity) / 100, 2)) AS total_sales, 
    CASE
        WHEN SUM(product.product_price * orders.order_quantity) / 100 >= 100000 THEN 'High'
        WHEN SUM(product.product_price * orders.order_quantity) / 100 >= 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_tier
FROM seller 
JOIN product ON seller.seller_id = product.seller_id
JOIN orders ON product.product_id = orders.product_id
GROUP BY seller.seller_id, seller.seller_name
ORDER BY SUM(product.product_price * orders.order_quantity) DESC;


-- SELECT * FROM seller_sales_tiers;


-- EXPLAIN
-- SELECT seller.seller_id AS seller_id, product.product_id AS product_id, product.product_name AS product_name,
--            CONCAT('$', FORMAT(SUM(product.product_price * orders.order_quantity) / 100, 2)) AS total_sales
   
--     FROM seller 
--     JOIN product ON seller.seller_id = "38973"
--     JOIN orders ON product.product_id = "84245"
--     WHERE seller.seller_name = Kassulke, "Rice and McCullough"
--     GROUP BY seller.seller_id, product.product_id, product.product_name
--     ORDER BY SUM(product.product_price * orders.order_quantity) DESC;


-- DROP PROCEDURE IF EXISTS top_products_for_seller;
DELIMITER $$

CREATE PROCEDURE top_products_for_seller(IN in_seller_name VARCHAR(255))
BEGIN 
    SELECT seller.seller_id AS seller_id, product.product_id AS product_id, product.product_name AS product_name,
           CONCAT('$', FORMAT(SUM(product.product_price * orders.order_quantity) / 100, 2)) AS total_sales
   
    FROM seller 
    JOIN product ON seller.seller_id = product.seller_id
    JOIN orders ON product.product_id = orders.product_id
    WHERE seller.seller_name = in_seller_name
    GROUP BY seller.seller_id, product.product_id, product.product_name
    ORDER BY SUM(product.product_price * orders.order_quantity) DESC;
END $$

DELIMITER ;




-- EXPLAIN
--  SELECT seller.seller_id AS seller_id, orders.order_id AS order_id, orders.order_date AS order_date, 
--     CONCAT('$', FORMAT(product.product_price * orders.order_quantity / 100, 2))  AS order_total, 
--     CONCAT('$', FORMAT(
--             SUM(product.product_price * orders.order_quantity)
--             OVER (PARTITION BY seller.seller_id
--                   ORDER BY orders.order_date, orders.order_id) / 100, 2)
--         ) AS running_total

--     FROM seller 
--     JOIN product ON seller.seller_id = 38973
--     JOIN orders ON product.product_id = 84245
--     WHERE seller.seller_name = "Kassulke, Rice and McCullough" ;

-- DROP PROCEDURE IF EXISTS seller_running_totals;
DELIMITER $$

CREATE PROCEDURE seller_running_totals(IN in_seller_name VARCHAR(255))
BEGIN 
    SELECT seller.seller_id AS seller_id, orders.order_id AS order_id, orders.order_date AS order_date, 
    CONCAT('$', FORMAT(product.product_price * orders.order_quantity / 100, 2))  AS order_total, 
    CONCAT('$', FORMAT(
            SUM(product.product_price * orders.order_quantity)
            OVER (PARTITION BY seller.seller_id
                  ORDER BY orders.order_date, orders.order_id) / 100, 2)
        ) AS running_total

    FROM seller 
    JOIN product ON seller.seller_id = product.seller_id
    JOIN orders ON product.product_id = orders.product_id
    WHERE seller.seller_name = in_seller_name ;
END $$

DELIMITER ;

-- CALL seller_running_totals('Kassulke, Rice and McCullough');

-- SELECT * 
-- FROM   seller_sales_tiers
-- ORDER  BY total_sales DESC;


INSERT IGNORE INTO country (country)
SELECT DISTINCT country FROM denormalized_orders
UNION
SELECT DISTINCT seller_country FROM denormalized_orders;

INSERT IGNORE INTO city (city, country_id)
SELECT DISTINCT d.city, c.country_id
FROM denormalized_orders d
JOIN country c ON c.country = d.country;

INSERT IGNORE INTO seller (seller_id, seller_name, seller_country)
SELECT DISTINCT d.seller_id, d.seller_name, c.country_id
FROM denormalized_orders d
JOIN country c ON c.country = d.seller_country;

INSERT IGNORE INTO product (product_id, product_name, product_price, seller_id)
SELECT DISTINCT product_id, product_name, product_price, seller_id
FROM denormalized_orders;

INSERT IGNORE INTO buyer (buyer_id, first_name, last_name, email, address, city_id)
SELECT DISTINCT d.buyer_id, d.first_name, d.last_name, d.email, d.address, ci.city_id
FROM denormalized_orders d
JOIN city ci ON ci.city = d.city
JOIN country co ON co.country = d.country AND co.country_id = ci.country_id;

INSERT IGNORE INTO credit_card (cc_number, cc_exp, buyer_id)
SELECT DISTINCT d.cc_number, d.cc_exp, b.buyer_id
FROM denormalized_orders d
JOIN buyer b ON b.email = d.email;

INSERT IGNORE INTO orders (order_id, order_quantity, order_date, product_id, buyer_id, cc_id)
SELECT d.order_id, d.order_quantity, d.order_date, d.product_id, d.buyer_id, cc.cc_id
FROM denormalized_orders d
JOIN credit_card cc ON cc.buyer_id = d.buyer_id AND cc.cc_number = d.cc_number;

INSERT IGNORE INTO reviews (order_id, review, rating)
SELECT order_id, review, rating
FROM denormalized_orders;










-- select * from denormalized_orders;
-- CALL sales_for_month(3, 2026);













CALL sales_for_month( "2019-07-23");


-- CALL sales_for_month('2020-04-01');


-- SELECT *
-- FROM product;

-- SELECT *
-- FROM reviews;

-- SELECT *
-- FROM buyer;

-- SELECT * FROM credit_card;

-- -- SELECT DISTINCT cc_number FROM denormalized_orders
-- -- WHERE cc_number NOT IN (SELECT cc_number FROM credit_card);

-- SELECT *
-- FROM orders;

-- SELECT DISTINCT buyer_id
-- FROM denormalized_orders;

-- SELECT *
-- FROM seller;
-- SELECT COUNT(DISTINCT seller_id) FROM denormalized_orders;

-- SELECT COUNT(order_id) FROM orders;

-- EXPLAIN
-- SELECT buyer.buyer_id, buyer.first_name, buyer.last_name, SUM(product.product_price * orders.order_quantity) AS total_amount_spent
-- FROM buyer
-- JOIN orders on buyer.buyer_id = orders.buyer_id
-- JOIN address on buyer.address_id = address.address_id
-- JOIN city on address.city_id = city.city_id
-- JOIN country on city.country_id = country.country_id
-- JOIN product on product.product_id = orders.product_id
-- WHERE country.country = 'United States'
-- GROUP BY buyer.buyer_id, buyer.first_name, buyer.last_name
-- ORDER BY total_amount_spent DESC
-- LIMIT 10;

-- SELECT order_id, COUNT( DISTINCT product_id)
-- FROM denormalized_orders
-- GROUP BY order_id
-- HAVING  COUNT( DISTINCT product_id) >1
-- Limit 5;

-- SELECT order_id, COUNT(DISTINCT buyer_id)
-- FROM denormalized_orders
-- GROUP BY order_id
-- HAVING COUNT(DISTINCT buyer_id) > 1;

-- SELECT order_id, COUNT(DISTINCT product_id) AS products
-- FROM   denormalized_orders
-- GROUP  BY order_id
-- HAVING products > 1
-- LIMIT 5;

--  Does any order contain more than one seller?
-- SELECT order_id, COUNT(DISTINCT seller_id) AS sellers
-- FROM   denormalized_orders
-- GROUP  BY order_id
-- HAVING sellers > 1
-- LIMIT 5;

-- SELECT product_id
-- FROM   product
-- GROUP  BY product_id
-- HAVING COUNT(DISTINCT product_price) > 1;

-- SELECT address, COUNT( DISTINCT buyer_id)
-- FROM denormalized_orders
-- GROUP BY address
-- HAVING  COUNT( DISTINCT buyer_id) >0
-- ;

-- SELECT product_id, COUNT(DISTINCT review) AS distinct_reviews
-- FROM denormalized_orders
-- GROUP BY product_id
-- HAVING distinct_reviews > 1;

-- SELECT order_id, COUNT(*) 
-- FROM denormalized_orders
-- GROUP BY order_id
-- HAVING COUNT(*) > 1;

-- SELECT buyer_id, COUNT(DISTINCT cc_number) AS num_cards
-- FROM denormalized_orders
-- -GROUP BY buyer_id
-- HAVING num_cards > 1;

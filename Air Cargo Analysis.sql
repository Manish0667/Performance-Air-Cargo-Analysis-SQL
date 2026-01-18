-- Create Database --
-----------------------------
CREATE DATABASE air_cargo;
USE air_cargo;

-- Import CSV files --
-------------------------
-- Use MySQL Workbench → Table Data Import Wizard
-- Import each CSV into its matching table.

-- Task 1: Create ER diagram --
-------------------------------
-- Create diagram using MySQL → Database → Reverse Engineer

-- Task 2: Create route_details Table with Constraints --
---------------------------------------------------------
CREATE TABLE route_details (
    route_id INT UNIQUE,
    flight_num VARCHAR(10) CHECK (flight_num LIKE 'FL%'),
    origin_airport VARCHAR(50),
    destination_airpoart VARCHAR(50),
    aircraft_id INT,
    distance_miles INT CHECK (distance_miles > 0)
    );

-- Task 3: Passengers Travelled Between Route 01–25 --
------------------------------------------------------
SELECT *
FROM passengers_on_flights
WHERE route_id BETWEEN 1 AND 25;

-- Task 4: Business Class Passengers & Revenue --
-------------------------------------------------
SELECT 
    COUNT(*) AS total_passengers,
    SUM(no_of_tickets * price_per_ticket) AS total_revenue
FROM ticket_details
WHERE class_id = 'Business';

-- Task 5: Display Full Name of Customers --
---------------------------------------
SELECT CONCAT(first_name, ' ', last_name) AS full_name
FROM customer;

-- Task 6: Customers Who Registered & Booked Tickets --
-------------------------------------------------------
SELECT DISTINCT c.customer_id, c.first_name, c.last_name
FROM customer c
JOIN ticket_details t
ON c.customer_id = t.customer_id;

-- Task 7: Customers by Brand (Emirates) --
-------------------------------------------
SELECT c.first_name, c.last_name
FROM customer c
JOIN ticket_details t
ON c.customer_id = t.customer_id
WHERE t.brand = 'Emirates';

-- Task 8: Economy Plus Customers (GROUP BY + HAVING) --
--------------------------------------------------------
SELECT customer_id
FROM passengers_on_flights
WHERE class_id = 'Economy Plus'
GROUP BY customer_id
HAVING COUNT(*) >= 1;

-- Task 9: Revenue Crossed 10000 (IF Clause) --
-----------------------------------------------
SELECT 
    IF(SUM(no_of_tickets * price_per_ticket) > 10000, 
       'Revenue Crossed 10000', 
       'Revenue Not Crossed') AS revenue_status
FROM ticket_details;

-- Task 10: Create & Grant Access to New User --
------------------------------------------------
CREATE USER 'air_user'@'localhost' IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON air_cargo.* TO 'air_user'@'localhost';
FLUSH PRIVILEGES;

-- Task 11: Maximum Ticket Price (Window Function) --
-----------------------------------------------------
SELECT 
    class_id,
    MAX(price_per_ticket) OVER (PARTITION BY class_id) AS max_price
FROM ticket_details;

-- Task 12: Improve Performance for Route ID = 4 --
---------------------------------------------------
CREATE INDEX idx_route_id 
ON passengers_on_flights(route_id);

-- Task 13: Execution Plan --
-----------------------------
EXPLAIN
SELECT *
FROM passengers_on_flights
WHERE route_id = 4;

-- Task 14: Total Ticket Price Using ROLLUP --
----------------------------------------------
SELECT 
    customer_id,
    aircraft_id,
    SUM(no_of_tickets * price_per_ticket) AS total_price
FROM ticket_details
GROUP BY customer_id, aircraft_id WITH ROLLUP;

-- Task 15: View for Business Class Customers --
------------------------------------------------
CREATE VIEW business_class_view AS
SELECT customer_id, brand
FROM ticket_details
WHERE class_id = 'Business';

-- Task 16: Stored Procedure – Route Range --
---------------------------------------------
CREATE PROCEDURE get_passengers_by_route(IN r1 INT, IN r2 INT)
BEGIN
    IF NOT EXISTS (
        SELECT * FROM information_schema.tables 
        WHERE table_name = 'passengers_on_flights'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Table does not exist';
    ELSE
        SELECT *
        FROM passengers_on_flights
        WHERE route_id BETWEEN r1 AND r2;
    END IF;
END

-- Task 17: Distance > 2000 Miles --
------------------------------------
CREATE PROCEDURE long_routes()
BEGIN
    SELECT *
    FROM routes
    WHERE distance_miles > 2000;
END;

call long_routes();

-- Task 18: Distance Categories Procedure --
--------------------------------------------
CREATE PROCEDURE route_category()
BEGIN
    SELECT route_id,
    CASE
        WHEN distance_miles <= 2000 THEN 'SDT'
        WHEN distance_miles <= 6500 THEN 'IDT'
        ELSE 'LDT'
    END AS travel_type
    FROM routes;
END;

-- Task 19: Complimentary Services Function + Procedure --
----------------------------------------------------------
CREATE FUNCTION complimentary(class_name VARCHAR(20))
RETURNS VARCHAR(5)
DETERMINISTIC
RETURN IF(class_name IN ('Business', 'Economy Plus'), 'Yes', 'No');

SELECT p_date, customer_id, class_id, complimentary(class_id) AS complimentary_service
FROM ticket_details;

-- Task 20: Cursor – Last Name Ends with Scott --
-------------------------------------------------
CREATE PROCEDURE scott_customer()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE fname VARCHAR(50);
    DECLARE cur CURSOR FOR
        SELECT first_name FROM customer WHERE last_name LIKE '%Scott';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;
    FETCH cur INTO fname;
    SELECT fname;
    CLOSE cur;
END
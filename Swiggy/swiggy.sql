SELECT * FROM swiggy_cleaned;

-- Checking for blank names
SELECT SUM(CASE WHEN hotel_name = "" THEN 1 ELSE 0 END) as hotel_name,
SUM(CASE WHEN rating = "" THEN 1 ELSE 0 END) as rating,
SUM(CASE WHEN time_minutes = "" THEN 1 ELSE 0 END) as time_minutes,
SUM(CASE WHEN food_type = "" THEN 1 ELSE 0 END) as food_type,
SUM(CASE WHEN location = "" THEN 1 ELSE 0 END) as location,
SUM(CASE WHEN offer_above = "" THEN 1 ELSE 0 END) as offer_above,
SUM(CASE WHEN offer_percentage = "" THEN 1 ELSE 0 END) as offer_percentage
FROM swiggy_cleaned;


-- Schemas
SELECT COLUMN_NAME FROM information_schema.columns WHERE table_name = "swiggy_cleaned";

SELECT group_concat(
		CONCAT('SUM(CASE WHEN `', COLUMN_NAME, '` = "" THEN 1 ELSE 0 END) as `', COLUMN_NAME, '`')
	) INTO @sql
FROM information_schema.columns WHERE table_name = "swiggy_cleaned";

SELECT @sql;
SET @sql = CONCAT('SELECT ', @sql, ' FROM swiggy_cleaned');
SELECT @sql;


-- Prepare
PREPARE smt FROM @sql;
EXECUTE smt;
deallocate prepare smt;


-- Shifting values of rating to time minutes
CREATE TABLE clean as
SELECT * FROM swiggy_cleaned WHERE rating LIKE '%mins%';

SELECT * FROM clean;

CREATE TABLE cleaned as
SELECT *, CAST(SUBSTRING_INDEX(rating, ' ', 1) AS UNSIGNED) as t FROM clean;

DROP table clean;

-- SET SQL_SAFE_UPDATES = 0;
UPDATE swiggy_cleaned as s INNER JOIN cleaned as c
ON c.hotel_name = s.hotel_name
SET s.time_minutes = c.t;

SELECT * FROM swiggy_cleaned;

DROP TABLE cleaned;


-- Cleaning for ( - )
CREATE TABLE clean
SELECT * FROM swiggy_cleaned WHERE time_minutes LIKE '%-%';

CREATE TABLE cleaned AS
SELECT *,
    CAST(SUBSTRING_INDEX(time_minutes, '-', 1) AS UNSIGNED) AS start_value,
    CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(time_minutes, '-', -1), '-', 1) AS UNSIGNED) AS end_value
FROM clean;

DROP TABLE clean;
SELECT * FROM cleaned;

UPDATE swiggy_cleaned as s INNER JOIN cleaned as c
ON c.hotel_name = s.hotel_name
SET s.time_minutes = (c.start_value + c.end_value)/2;

SELECT * FROM swiggy_cleaned;
DROP TABLE cleaned;


--             Time_minute column in cleaned

-- Cleaning ratings column
SELECT location, ROUND(AVG(rating), 1) FROM swiggy_cleaned
WHERE rating NOT LIKE '%mins%'
GROUP BY location;

UPDATE swiggy_cleaned as t
JOIN (
	SELECT location, ROUND(AVG(rating), 1) as avg_rating FROM swiggy_cleaned
	WHERE rating NOT LIKE '%mins%'
	GROUP BY location
) as avg_table ON t.location = avg_table.location
SET t.rating = avg_table.avg_rating
WHERE t.rating LIKE '%mins%';

SELECT * FROM swiggy_cleaned
WHERE rating LIKE "%mins%";

SET @average = (SELECT ROUND(AVG(rating),1) FROM swiggy_cleaned WHERE rating NOT LIKE "%mins%");
SELECT @average;

UPDATE swiggy_cleaned
SET rating = @average
WHERE rating LIKE "%mins%";

SELECT * FROM swiggy_cleaned;


--  Rating column cleaned

-- location columns
SELECT distinct location FROM swiggy_cleaned WHERE location LIKE "%Kandivali%";

UPDATE swiggy_cleaned
SET location = "Kandivali East"
WHERE location LIKE "%East%";

UPDATE swiggy_cleaned
SET location = "Kandivali West"
WHERE location LIKE "%West%";

UPDATE swiggy_cleaned
SET location = "Kandivali West"
WHERE location LIKE "%W%";

UPDATE swiggy_cleaned
SET location = "Kandivali East"
WHERE location LIKE "%E%";


-- CLeaning offer_percentage column
UPDATE swiggy_cleaned
SET offer_percentage = 0
WHERE offer_above = 'not_available';


-- Cleaning food_type

select distinct food from 
(
select *, substring_index( substring_index(food_type ,',',numbers.n),',', -1) as 'food'
from  swiggy_cleaned 
	join
	(
		select 1+a.N + b.N*10 as n from 
		(
			(
			SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
			UNION ALL SELECT 8 UNION ALL SELECT 9) a
			cross join 
			(
			SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
			UNION ALL SELECT 8 UNION ALL SELECT 9)b
		)
	)  as numbers 
    on  char_length(food_type)  - char_length(replace(food_type ,',','')) >= numbers.n-1
)a;
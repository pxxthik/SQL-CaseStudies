SELECT * FROM playstore;
TRUNCATE TABLE playstore;

LOAD DATA INFILE "D:/SQL-CaseStudies/Google Play Store/playstore.csv"
INTO TABLE playstore
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


-- 1. You're working as a market analyst for a mobile app development company.
--    Your task is to identify the most promising categories (TOP 5) for launching
--    new free apps based on their average ratings.

SELECT Category, ROUND(AVG(Rating), 2) AS "Rating" FROM playstore
WHERE Type = "Free"
GROUP BY Category ORDER BY Rating DESC LIMIT 0, 5;


-- 2. As a business strategist for a mobile app company, your objective is to pinpoint
--    the three categories that generate the most revenue from paid apps. This calculation is based on the
--    product of the app price and its number of installations.

SELECT Category, ROUND(AVG(revenue), 2) AS "revenue" FROM (
	SELECT *, (Installs*Price) AS "revenue" FROM playstore WHERE Type = "Paid"
) t GROUP BY Category
ORDER BY revenue DESC LIMIT 0, 3;


-- 3. As a data analyst for a gaming company, you're tasked with calculating the percentage of games within each category.
--    This information will help the company understand the distribution of gaming apps across different categories.

SELECT Category, (count/(SELECT COUNT(*) FROM playstore))*100 AS "percent" FROM (
	SELECT Category, COUNT(APP) AS "count" FROM playstore GROUP BY Category
) t;


-- 4. As a data analyst at a mobile app-focused market research firm you’ll recommend whether the company should develop
--    paid or free apps for each category based on the ratings of that category.

WITH category_with_types AS (
	SELECT t1.Category, free_apps_rating, paid_apps_rating FROM (
		SELECT Category, ROUND(AVG(Rating), 2) AS "free_apps_rating" FROM playstore
		WHERE Type = "Free" GROUP BY Category
	) t1 INNER JOIN (
		SELECT Category, ROUND(AVG(Rating), 2) AS "paid_apps_rating" FROM playstore
		WHERE Type = "Paid" GROUP BY Category
	) t2 ON t1.Category = t2.Category
)

SELECT *, CASE
	WHEN free_apps_rating > paid_apps_rating THEN "Free" ELSE "PAID"
END AS "decision"
FROM category_with_types;


-- 5. Suppose you're a database administrator your databases have been hacked and hackers are changing price of
--    certain apps on the database, it is taking long for IT team to neutralize the hack, however you as a responsible manager
--    don’t want your data to be changed, do some measure where the changes in price can be recorded as you can’t stop hackers
--    from making changes.

CREATE TABLE pricechangelog(
	App VARCHAR(255),
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    operation_type VARCHAR(255),
    operation_date TIMESTAMP
);

CREATE TABLE play AS SELECT * FROM playstore;

DELIMITER //
CREATE TRIGGER price_change_logger
AFTER UPDATE ON play
FOR EACH ROW
BEGIN
	INSERT INTO pricechangelog VALUES(new.App, old.Price, new.Price, "UPDATE", CURRENT_TIMESTAMP);
END;
// DELIMITER ;


-- 6. Your IT team have neutralized the threat; however, hackers have made some changes in the prices, but because of your
--    measure you have noted the changes, now you want correct data to be inserted into the database again.

-- UPDATE + JOIN

SELECT * FROM play as t1 INNER JOIN pricechangelog as t2 ON t1.App = t2.App;     -- Step 1

DROP TRIGGER price_change_logger;

UPDATE play as t1
INNER JOIN pricechangelog as t2 ON t1.App = t2.App
SET t1.price = t2.old_price;



-- 7. As a data person you are assigned the task of investigating the correlation between two numeric factors:
--    app ratings and the quantity of reviews.

-- Correlation = (x - x`) * (y- y`)
--            ------------------------------
--             SQRT((x - x`)^2 * (y- y`)^2)

SET @x = (SELECT ROUND(AVG(Rating), 2) FROM playstore);
SET @y = (SELECT ROUND(AVG(Reviews), 2) FROM playstore);

WITH t AS (
	SELECT *, ROUND(Rat*Rat, 2) as "sqr_x", ROUND(Rev*Rev, 2) as "sqr_y" FROM (
		SELECT Rating, ROUND((Rating - @x),2) as "Rat", Reviews, ROUND((Reviews - @y),2) as "Rev" FROM playstore
	) k
)

SELECT @numerator := SUM((Rat*Rev)), @deno_1 := SUM(sqr_x), @deno_2 := SUM(sqr_y) FROM t;
SELECT ROUND(@numerator / SQRT(@deno_1 * @deno_2), 2) AS "correlation_coef";


-- 8. Your boss noticed  that some rows in genres columns have multiple genres in them, which was creating issue when developing
--    the  recommender system from the data he/she assigned you the task to clean the genres column and make two genres out of it,
--    rows that have only one genre will have other column as blank.

DELIMITER //
CREATE FUNCTION f_name(a VARCHAR(100))
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    SET @l = LOCATE(';', a);

    SET @s = IF(@l > 0, LEFT(a, @l - 1), a);

    RETURN @s;
END//
DELIMITER ;


-- function for second genre
DELIMITER //
create function l_name(a varchar(100))
returns varchar(100)
deterministic 
begin
   set @l = locate(';',a);
   set @s = if(@l = 0 ,' ',substring(a,@l+1, length(a)));
   
   return @s;
end //
DELIMITER ;

select app, genres, f_name(genres) as 'gene 1', l_name(genres) as 'gene 2' from playstore;
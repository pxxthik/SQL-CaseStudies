SELECT * FROM sharktank;
TRUNCATE TABLE sharktank;

LOAD DATA INFILE "D:/SQL-CaseStudies/Shark Tank India/sharktank.csv"
INTO TABLE sharktank
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


-- 1. You Team must promote shark Tank India season 4, The senior come up with the idea to show highest
--    funding domain wise so that new startups can be attracted, and you were assigned the task to show the same.

SELECT Industry, Total_Deal_Amount_in_lakhs FROM (
	SELECT Industry, Total_Deal_Amount_in_lakhs,
	ROW_NUMBER() OVER(PARTITION BY Industry ORDER BY Total_Deal_Amount_in_lakhs DESC) AS "rnk" FROM sharktank
	GROUP BY Industry, Total_Deal_Amount_in_lakhs
) t WHERE rnk = 1;


-- 2. You have been assigned the role of finding the domain where female as pitchers have female to male pitcher ratio >70%

SELECT *, (female/male) * 100 AS 'ratio' FROM (
	SELECT Industry, SUM(Male_Presenters) AS "male", SUM(Female_Presenters) AS "female"
	FROM sharktank GROUP BY Industry
	HAVING SUM(Male_Presenters) > 0 AND SUM(Female_Presenters) > 0
) t WHERE (female/male) * 100 > 70;


-- 3. You are working at marketing firm of Shark Tank India, you have got the task to determine volume of per season
--    sale pitch made, pitches who received offer and pitches that were converted. Also show the percentage of pitches
--    converted and percentage of pitches entertained.

SELECT a.Season_Number, total, recieved_offer, recieved_offer/total*100 AS "r_%",
accepted_offer, accepted_offer/total * 100 AS "a_%" FROM (
	SELECT Season_Number, COUNT(Startup_Name) AS "total" FROM sharktank
	GROUP BY Season_Number
) a INNER JOIN (
	SELECT Season_Number, COUNT(Startup_Name) AS "recieved_offer" FROM sharktank
	WHERE Received_Offer = "Yes"
	GROUP BY Season_Number
) b ON a.Season_Number = b.Season_Number INNER JOIN (
	SELECT Season_Number, COUNT(Startup_Name) AS "accepted_offer" FROM sharktank
	WHERE Received_Offer = "Yes" AND Accepted_Offer = "Yes"
	GROUP BY Season_Number
) c ON b.Season_Number = c.Season_Number;



-- 4. As a venture capital firm specializing in investing in startups featured on a renowned entrepreneurship TV show,
--    you are determining the season with the highest average monthly sales and identify the top 5 industries with the
--    highest average monthly sales during that season to optimize investment decisions?

SET @season = (
	SELECT Season_Number FROM (
		SELECT Season_Number, ROUND(AVG(Monthly_Sales_in_lakhs), 2) AS "average" FROM sharktank
		GROUP BY Season_Number ORDER BY average DESC LIMIT 0, 1
	) t
);

SELECT Industry, ROUND(AVG(Monthly_Sales_in_lakhs), 2) AS "average" FROM sharktank
WHERE Season_Number = @season
GROUP BY Industry ORDER BY average DESC LIMIT 0, 5;



-- 5. As a data scientist at our firm, your role involves solving real-world challenges like identifying industries
--    with consistent increases in funds raised over multiple seasons. This requires focusing on industries where data is
--    available across all three seasons. Once these industries are pinpointed, your task is to delve into the specifics,
--    analyzing the number of pitches made, offers received, and offers converted per season within each industry.

WITH valid_industries AS (
	SELECT Industry,
	MAX(CASE WHEN Season_Number = 1 THEN Total_Deal_Amount_in_lakhs END) AS "season_1_amt",
	MAX(CASE WHEN Season_Number = 2 THEN Total_Deal_Amount_in_lakhs END) AS "season_2_amt",
	MAX(CASE WHEN Season_Number = 3 THEN Total_Deal_Amount_in_lakhs END) AS "season_3_amt" FROM sharktank
	GROUP BY Industry
	HAVING season_1_amt < season_2_amt AND season_2_amt < season_3_amt AND season_1_amt != 0
)

SELECT b.Season_Number, a.Industry, COUNT(b.Startup_Name) AS "total",
COUNT(CASE WHEN b.Received_Offer = "Yes" THEN b.Startup_Name END) AS "recieved",
COUNT(CASE WHEN b.Accepted_Offer = "Yes" THEN b.Startup_Name END) AS "accepted"
FROM valid_industries as a INNER JOIN sharktank as b
ON a.Industry = b.Industry
GROUP BY b.Season_Number, a.Industry;



-- 6. Every shark wants to know in how much year their investment will be returned, so you must create a system for them,
--    where shark will enter the name of the startup’s and the based on the total deal and equity given in how many years
--    their principal amount will be returned and make their investment decisions.

delimiter //
CREATE PROCEDURE tot(IN startup VARCHAR(100))
BEGIN
	CASE
		WHEN (SELECT Accepted_Offer = "No" FROM sharktank WHERE Startup_Name = startup)
			THEN (SELECT "TOT cant be calculated as startup didnt accept the offer");
		WHEN (SELECT Accepted_Offer = "Yes" AND Yearly_Revenue_in_lakhs = "Not Mentioned" FROM sharktank WHERE Startup_Name = startup)
			THEN (SELECT "TOT cant be calculated as past data is not available");
		ELSE
			SELECT `Startup_Name`, `Yearly_Revenue_in_lakhs`, `Total_Deal_Amount_in_lakhs`, `Total_Deal_Equity_%`,
            `Total_Deal_Amount_in_lakhs`/((`Total_Deal_Equity_%`/100)*`Total_Deal_Amount_in_lakhs`) as 'years'
            FROM sharktank WHERE Startup_Name = startup;
	END CASE;
END

// delimiter ;

CALL tot('BluePineFoods');



-- 7. In the world of startup investing, we're curious to know which big-name investor, often referred to as "sharks,"
--    tends to put the most money into each deal on average. This comparison helps us see who's the most generous
--    with their investments and how they measure up against their fellow investors.

SELECT sharkname, ROUND(AVG(investment), 2) AS average FROM (
	SELECT `Namita_Investment_Amount_in_lakhs` as investment, "Namita" as sharkname FROM sharktank
	WHERE `Namita_Investment_Amount_in_lakhs` > 0
	UNION ALL
	SELECT `Vineeta_Investment_Amount_in_lakhs` as investment, "Vineeta" as sharkname FROM sharktank
	WHERE `Vineeta_Investment_Amount_in_lakhs` > 0
	UNION ALL
	SELECT `Anupam_Investment_Amount_in_lakhs` as investment, "Anupam" as sharkname FROM sharktank
	WHERE `Anupam_Investment_Amount_in_lakhs` > 0
	UNION ALL
	SELECT `Aman_Investment_Amount_in_lakhs` as investment, "Aman" as sharkname FROM sharktank
	WHERE `Aman_Investment_Amount_in_lakhs` > 0
	UNION ALL
	SELECT `Peyush_Investment_Amount_in_lakhs` as investment, "Peyush" as sharkname FROM sharktank
	WHERE `Peyush_Investment_Amount_in_lakhs` > 0
	UNION ALL
	SELECT `Ashneer_Investment_Amount` as investment, "Ashneer" as sharkname FROM sharktank
	WHERE `Ashneer_Investment_Amount` > 0
) t GROUP BY sharkname ORDER BY average DESC;



-- 8. Develop a stored procedure that accepts inputs for the season number and the name of a shark. The procedure will
--    then provide detailed insights into the total investment made by that specific shark across different industries
--    during the specified season. Additionally, it will calculate the percentage of their investment in each sector
--    relative to the total investment in that year, giving a comprehensive understanding of the shark's investment
--    distribution and impact.

DELIMITER //
create PROCEDURE getseasoninvestment(IN season INT, IN sharkname VARCHAR(100))
BEGIN
      
    CASE 

        WHEN sharkname = 'namita' THEN
            set @total = (select  sum(`Namita_Investment_Amount_in_lakhs`) from sharktank where Season_Number= season );
            SELECT Industry, sum(`Namita_Investment_Amount_in_lakhs`) as 'sum' ,(sum(`Namita_Investment_Amount_in_lakhs`)/@total)*100 as 'Percent' FROM sharktank WHERE season_Number = season AND `Namita_Investment_Amount_in_lakhs` > 0
            group by industry;
        WHEN sharkname = 'Vineeta' THEN
            SELECT industry,sum(`Vineeta_Investment_Amount_in_lakhs`) as 'sum' FROM sharktank WHERE season_Number = season AND `Vineeta_Investment_Amount_in_lakhs` > 0
            group by industry;
        WHEN sharkname = 'Anupam' THEN
            SELECT industry,sum(`Anupam_Investment_Amount_in_lakhs`) as 'sum' FROM sharktank WHERE season_Number = season AND `Anupam_Investment_Amount_in_lakhs` > 0
            group by Industry;
        WHEN sharkname = 'Aman' THEN
            SELECT industry,sum(`Aman_Investment_Amount_in_lakhs`) as 'sum'  FROM sharktank WHERE season_Number = season AND `Aman_Investment_Amount_in_lakhs` > 0
             group by Industry;
        WHEN sharkname = 'Peyush' THEN
             SELECT industry,sum(`Peyush_Investment_Amount_in_lakhs`) as 'sum'  FROM sharktank WHERE season_Number = season AND `Peyush_Investment_Amount_in_lakhs` > 0
             group by Industry;
        WHEN sharkname = 'Amit' THEN
              SELECT industry,sum(`Amit_Investment_Amount_in_lakhs`) as 'sum'   WHERE season_Number = season AND `Amit_Investment_Amount_in_lakhs` > 0
             group by Industry;
        WHEN sharkname = 'Ashneer' THEN
            SELECT industry,sum(`Ashneer_Investment_Amount`)  FROM sharktank WHERE season_Number = season AND `Ashneer_Investment_Amount` > 0
             group by Industry;
        ELSE
            SELECT 'Invalid shark name';
    END CASE;
    
END //
DELIMITER ;

call getseasoninvestment(2, 'Namita');

set @total = (select  sum(Total_Deal_Amount_in_lakhs) from sharktank where Season_Number= 1 );
select @total;


-- 9. In the realm of venture capital, we're exploring which shark possesses the most diversified investment portfolio
--    across various industries. By examining their investment patterns and preferences, we aim to uncover any discernible
--    trends or strategies that may shed light on their decision-making processes and investment philosophies.


-- 10. Explain the concept of indexes in MySQL. How do indexes improve query performance, and what factors should be
--     considered when deciding which columns to index in a database table

SELECT * FROM sharktank
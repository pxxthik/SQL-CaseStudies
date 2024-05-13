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
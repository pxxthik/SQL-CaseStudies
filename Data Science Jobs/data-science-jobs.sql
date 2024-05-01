-- 1. You're a Compensation analyst employed by a multinational corporation.
--    Your Assignment is to Pinpoint Countries who give work fully remotely,
--    for the title 'managers’ Paying salaries Exceeding $90,000 USD

SELECT DISTINCT company_location FROM salaries
WHERE job_title like "%Manager%" AND salary_in_usd > 90000 and remote_ratio = 100;


-- 2. AS a remote work advocate Working for a progressive HR tech startup who place their freshers’
--    clients IN large tech firms. you're tasked WITH Identifying top 5 Country Having greatest count of
--    large (company size) number of companies.

SELECT company_location, COUNT(*) as "cnt" FROM (
	SELECT * FROM salaries
	WHERE experience_level = "EN" and company_size = "L"
) t
GROUP BY company_location
ORDER BY cnt DESC
LIMIT 0, 5;


-- 3. Picture yourself AS a data scientist Working for a workforce management platform.
--    Your objective is to calculate the percentage of employees. Who enjoy fully remote roles
--    WITH salaries Exceeding $100,000 USD, Shedding light ON the attractiveness of high-paying
--    remote positions IN today's job market.

SET @total = (SELECT COUNT(*) FROM salaries WHERE salary_in_usd > 100000);
SET @count = (SELECT COUNT(*) FROM salaries WHERE salary_in_usd > 100000 and remote_ratio = 100);
SET @percentage = ((SELECT @count)/(SELECT @total) * 100);
SELECT ROUND(@percentage, 2) as "percentage";


-- 4. Imagine you're a data analyst Working for a global recruitment agency.
--    Your Task is to identify the Locations where entry-level average salaries exceed the
--    average salary for that job title IN market for entry level, helping your agency guide candidates
--    towards lucrative opportunities.

SELECT t1.job_title, company_location, avg_sal, avg_sal_per_country FROM (
	SELECT job_title, AVG(salary) as "avg_sal" FROM salaries WHERE experience_level = "EN" GROUP BY job_title
) t1 INNER JOIN (
	SELECT company_location, job_title, AVG(salary) as "avg_sal_per_country" FROM salaries
    WHERE experience_level = "EN" GROUP BY company_location, job_title
) t2 ON t1.job_title = t2.job_title
WHERE avg_sal_per_country > avg_sal;


-- 5. You've been hired by a big HR Consultancy to look at how much people get paid IN different Countries.
--    Your job is to Find out for each job title which. Country pays the maximum average salary.
--    This helps you to place your candidates IN those countries.

SELECT job_title, company_location, avg_sal as "avg_max_sal" FROM (
	SELECT *, DENSE_RANK() OVER(PARTITION BY job_title ORDER BY avg_sal DESC) as "rnk" FROM (
		SELECT job_title, company_location, AVG(salary) as "avg_sal" FROM salaries
		GROUP BY job_title, company_location
	) t1
) t2 WHERE rnk =1;


-- 6. AS a data-driven Business consultant, you've been hired by a multinational corporation to
--    analyze salary trends across different company Locations. Your goal is to Pinpoint Locations WHERE the
--    average salary Has consistently Increased over the Past few years (Countries WHERE data is available for
--    3 years Only(present year and past two years) providing Insights into Locations experiencing Sustained salary growth.

WITH tbl as(
	SELECT * FROM salaries WHERE company_location IN (
		SELECT company_location FROM (
			SELECT company_location FROM salaries
			WHERE work_year >= YEAR(CURRENT_DATE()) - 2
			GROUP BY company_location HAVING COUNT(DISTINCT work_year) = 3
		) t
	)
)

SELECT 
    company_location,
    MAX(CASE WHEN work_year = 2022 THEN  average END) AS AVG_salary_2022,
    MAX(CASE WHEN work_year = 2023 THEN average END) AS AVG_salary_2023,
    MAX(CASE WHEN work_year = 2024 THEN average END) AS AVG_salary_2024
FROM 
(
SELECT company_location, work_year, AVG(salary_in_usd) AS average FROM  tbl GROUP BY company_location, work_year 
)q GROUP BY company_location  havINg AVG_salary_2024 > AVG_salary_2023 AND AVG_salary_2023 > AVG_salary_2022;


-- 7. Picture yourself AS a workforce strategist employed by a global HR tech startup.
--    Your Mission is to Determine the percentage of fully remote work for each experience
--    level IN 2021 and compare it WITH the corresponding figures for 2024, Highlighting any significant
--    Increases or decreases IN remote work Adoption over the years.

WITH t1 AS (
	SELECT a.experience_level, total_remote ,total_2021, ROUND((((total_remote)/total_2021)*100),2) AS '2021 remote %' FROM( 
	   SELECT experience_level, COUNT(experience_level) AS total_remote FROM salaries
       WHERE work_year=2021 and remote_ratio = 100 GROUP BY experience_level
	)a
	INNER JOIN(
	  SELECT  experience_level, COUNT(experience_level) AS total_2021 FROM salaries
      WHERE work_year=2021 GROUP BY experience_level
	)b ON a.experience_level= b.experience_level
  ),
  t2 AS(
	SELECT a.experience_level, total_remote ,total_2024, ROUND((((total_remote)/total_2024)*100),2)AS '2024 remote %' FROM( 
		SELECT experience_level, COUNT(experience_level) AS total_remote FROM salaries
        WHERE work_year=2024 and remote_ratio = 100 GROUP BY experience_level
	)a
	INNER JOIN(
	SELECT  experience_level, COUNT(experience_level) AS total_2024 FROM salaries
    WHERE work_year=2024 GROUP BY experience_level
	)b ON a.experience_level= b.experience_level
  ) 
  
 SELECT * FROM t1 INNER JOIN t2 ON t1.experience_level = t2.experience_level;
 
 
 -- 8. AS a Compensation specialist at a Fortune 500 company, you're tasked WITH analyzing salary trends over time.
 --    Your objective is to calculate the average salary increase percentage for each experience level and job title
 --    between the years 2023 and 2024, helping the company stay competitive IN the talent market.
 
 WITH t as (
	SELECT experience_level, job_title ,work_year, round(AVG(salary_in_usd),2) AS 'average' FROM salaries
	WHERE work_year IN (2023, 2024)
	GROUP BY experience_level, job_title, work_year
)

SELECT *,round((((AVG_salary_2024-AVG_salary_2023)/AVG_salary_2023)*100),2)  AS changes FROM (
	SELECT experience_level, job_title,
	MAX(CASE WHEN work_year = 2023 THEN average END) as AVG_salary_2023,
	MAX(CASE WHEN work_year = 2024 THEN average END) as AVG_salary_2024
	FROM  t GROUP BY experience_level , job_title
) a WHERE (((AVG_salary_2024-AVG_salary_2023)/AVG_salary_2023)*100)  IS NOT NULL;


-- 9. You're a database administrator tasked with role-based access control for a company's employee database.
--    Your goal is to implement a security measure where employees in different experience level
--    (e.g. Entry Level, Senior level etc.) can only access details relevant to their respective experience level,
--    ensuring data confidentiality and minimizing the risk of unauthorized access.

SHOW PRIVILEGES;

CREATE USER "Entry_Level"@"%" IDENTIFIED BY "EN";
CREATE USER "Junior_Mid_Level"@"%" IDENTIFIED BY "MI";

CREATE VIEW entry_level AS
SELECT * FROM salaries WHERE experience_level = "EN";

GRANT SELECT ON sql_casestudy.entry_level TO "Entry_Level"@"%";



-- 10. You are working with a consultancy firm, your client comes to you with certain data and preferences
--     such as (their year of experience , their employment type, company location and company size )  and want to
--     make an transaction into different domain in data industry (like  a person is working as a data analyst and
--     want to move to some other domain such as data science or data engineering etc.) your work is to  guide them to
--     which domain they should switch to base on  the input they provided, so that they can now update their knowledge as
--     per the suggestion/.. The Suggestion should be based on average salary.
SELECT * FROM salaries
DELIMITER //

CREATE PROCEDURE GetAvgSal(IN exp_lvl VARCHAR(2), IN emp_type VARCHAR(3), IN cmp_loc VARCHAR(2), IN cmp_SIZE VARCHAR(2))
BEGIN

SELECT job_title, experience_level, employment_type, company_location, company_size, AVG(salary_in_usd) as avg_sal FROM salaries
WHERE experience_level = exp_lvl AND employment_type = emp_type AND company_location = cmp_loc AND company_size = cmp_size
GROUP BY experience_level, employment_type, company_location, company_size, job_title
ORDER BY avg_sal DESC;

END //

DELIMITER ;

call GetAvgSal('EN','FT','AU','M');
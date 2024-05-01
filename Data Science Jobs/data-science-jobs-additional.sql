-- 1. As a market researcher, your job is to Investigate the job market for a company that analyzes workforce data.
--    Your Task is to know how many people were employed IN different types of companies AS per their size IN 2021.

SELECT company_size, COUNT(company_size) as "num" FROM salaries WHERE work_year = 2021
GROUP BY company_size;


-- 2. Imagine you are a talent Acquisition specialist Working for an International recruitment agency.
--    Your Task is to identify the top 3 job titles that command the highest average salary Among part-time
--    Positions IN the year 2023. However, you are Only Interested IN Countries WHERE there are more than 50 employees,
--    Ensuring a robust sample size for your analysis.

SELECT job_title, AVG(salary_in_usd) as "average" FROM salaries
WHERE company_location IN (
	SELECT company_location FROM (
		SELECT company_location FROM salaries
		GROUP BY company_location
		HAVING COUNT(*) > 50
    ) t
) AND employment_type = "PT" AND work_year = 2023
GROUP BY job_title
ORDER BY average DESC
LIMIT 0, 3;


-- 3. As a database analyst you have been assigned the task to
--    Select Countries where average mid-level salary is higher than overall mid-level salary for the year 2023.

SELECT company_location FROM salaries
GROUP BY company_location
HAVING AVG(salary_in_usd) > (
	SELECT AVG(salary_in_usd) FROM salaries
	WHERE experience_level = "MI"
);


-- 4. As a database analyst you have been assigned the task to Identify the company locations
--    with the highest and lowest average salary for senior-level (SE) employees in 2023.

DELIMITER //

CREATE PROCEDURE GetSenierSalaryStats()
BEGIN
	SELECT company_location as highest_paying_location, AVG(salary_in_usd) as heighest_salary FROM salaries
    WHERE work_year = 2023 AND experience_level = "SE"
    GROUP BY company_location
    ORDER BY heighest_salary DESC
    LIMIT 0, 1;
    
    SELECT company_location as lowest_paying_location, AVG(salary_in_usd) as lowest_salary FROM salaries
    WHERE work_year = 2023 AND experience_level = "SE"
    GROUP BY company_location
    ORDER BY heighest_salary ASC
    LIMIT 0, 1;
END //

DELIMITER ;

CALL GetSenierSalaryStats();


-- 5. You're a Financial analyst Working for a leading HR Consultancy, and your Task is to
--    Assess the annual salary growth rate for various job titles. By Calculating the percentage Increase
--    IN salary FROM previous year to this year, you aim to provide valuable Insights Into salary trends WITHIN different job roles.

WITH t AS (
	SELECT t1.job_title, average_2023, average_2024 FROM (
		SELECT job_title, AVG(salary_in_usd) as average_2023 FROM salaries
		WHERE work_year = 2023
		GROUP BY job_title
	) t1 INNER JOIN (
		SELECT job_title, AVG(salary_in_usd) as average_2024 FROM salaries
		WHERE work_year = 2024
		GROUP BY job_title
	) t2 ON t1.job_title = t2.job_title
)

SELECT *, ROUND((average_2024 - average_2023)/average_2023 * 100, 2) AS percentage_change FROM t;


-- 6. You've been hired by a global HR Consultancy to identify Countries experiencing significant salary growth for entry-level roles.
--    Your task is to list the top three Countries with the highest salary growth rate FROM 2020 to 2023,
--    Considering Only companies with more than 50 employees, helping multinational Corporations identify Emerging talent markets.

WITH t as (
	SELECT company_location, work_year, AVG(salary_in_usd) as average FROM salaries
	WHERE experience_level = "EN" OR work_year IN (2020, 2023)
	GROUP BY company_location, work_year
)

SELECT * FROM (
	SELECT *, ((avg_salary_2023 - avg_salary_2020)/avg_salary_2020) * 100 as "growth" FROM (
		SELECT company_location,
		MAX(CASE WHEN work_year = 2020 THEN average END) as avg_salary_2020,
		MAX(CASE WHEN work_year = 2023 THEN average END) as avg_salary_2023 FROM t
		GROUP BY company_location
	) t
) t2 WHERE growth IS NOT NULL
ORDER BY growth DESC LIMIT 0, 3;


-- 7. Picture yourself as a data architect responsible for database management.
--    Companies in US and AU(Australia) decided to create a hybrid model for employees they decided that employees
--    earning salaries exceeding $90000 USD, will be given work from home. You now need to update the remote work ratio
--    for eligible employees, ensuring efficient remote work management while implementing appropriate error
--    handling mechanisms for invalid input parameters.

CREATE TABLE camp AS SELECT * FROM salaries;
-- creating temporary table so that changes are not made in actual table as actual table is being used in other cases also.

 -- by default mysql runs on safe update mode , this mode  is a safeguard against updating
 -- or deleting large portion of  a table.
 -- We will turn off safe update mode using set_sql_safe_updates
 SET SQL_SAFE_UPDATES = 0;
 
UPDATE camp 
SET remote_ratio = 100
WHERE (company_location = 'AU' OR company_location ='US')AND salary_in_usd > 90000;

SELECT * FROM camp WHERE (company_location = 'AU' OR company_location ='US')AND salary_in_usd > 90000;


-- 8. In the year 2024, due to increased demand in the data industry, there was an increase in salaries of data field employees.
--     a.	Entry Level-35% of the salary.
--     b.	Mid junior – 30% of the salary.
--     c.	Immediate senior level- 22% of the salary.
--     d.	Expert level- 20% of the salary.
--     e.	Director – 15% of the salary.
--    You must update the salaries accordingly and update them back in the original database.

UPDATE camp
SET salary_in_usd = 
	CASE
		WHEN experience_level = "EN" THEN salary_in_usd * 1.35
        WHEN experience_level = "MI" THEN salary_in_usd * 1.30
        WHEN experience_level = "SE" THEN salary_in_usd * 1.22
        WHEN experience_level = "EX" THEN salary_in_usd * 1.20
        WHEN experience_level = "DX" THEN salary_in_usd * 1.15
	END
WHERE work_year = 2024;


-- 9. You are a researcher and you have been assigned the task to
--    Find the year with the highest average salary for each job title.

SELECT job_title, work_year FROM (
	SELECT *, RANK() OVER(PARTITION BY job_title ORDER BY average DESC) AS rnk FROM (
		SELECT job_title, work_year, AVG(salary_in_usd) AS average FROM salaries
		GROUP BY job_title, work_year
	) t1
) t2 WHERE rnk = 1;


-- 10. You have been hired by a market research agency where you been assigned the task to
--     show the percentage of different employment type (full time, part time) in Different job roles,
--     in the format where each row will be job title, each column will be type of employment type and cell value
--     for that row and column will show the % value.

SELECT job_title,
ROUND(SUM(CASE WHEN employment_type = "FT" THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS FT_percent,
ROUND(SUM(CASE WHEN employment_type = "CT" THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS CT_percent,
ROUND(SUM(CASE WHEN employment_type = "PT" THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS PT_percent,
ROUND(SUM(CASE WHEN employment_type = "FL" THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS FL_percent
FROM salaries
GROUP BY job_title;
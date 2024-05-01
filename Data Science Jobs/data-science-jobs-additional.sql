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
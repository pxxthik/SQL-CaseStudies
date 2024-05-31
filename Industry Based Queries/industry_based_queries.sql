-- 1. You have got duplciate rows in table you have to delete them.

CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL
);

-- Insert 15 rows into the employees table
INSERT INTO employees (first_name, last_name, email, hire_date)
VALUES ('John', 'Doe', 'johndoe@example.com', '2022-01-15'),
       ('Jane', 'Smith', 'janesmith@example.com', '2021-11-30'),
       ('Alice', 'Johnson', 'alicejohnson@example.com', '2022-03-10'),
       ('David', 'Brown', 'davidbrown@example.com', '2022-02-20'),
       ('Emily', 'Davis', 'emilydavis@example.com', '2022-04-05'),
       ('Michael', 'Wilson', 'michaelwilson@example.com', '2022-01-05'),
       ('Sarah', 'Taylor', 'sarahtaylor@example.com', '2022-03-25'),
       ('Kevin', 'Clark', 'kevinclark@example.com', '2022-02-15'),
       ('Jessica', 'Anderson', 'jessicaanderson@example.com', '2022-04-01'),
       ('Matthew', 'Martinez', 'matthewmartinez@example.com', '2022-01-10'),
       ('Laura', 'Robinson', 'laurarobinson@example.com', '2022-03-15'),
       ('Daniel', 'White', 'danielwhite@example.com', '2022-02-05'),
       ('Amy', 'Harris', 'amyharris@example.com', '2022-04-20'),
       ('Jason', 'Lee', 'jasonlee@example.com', '2022-01-20'),
       ('Rachel', 'Moore', 'rachelmoore@example.com', '2022-03-05');


-- inserting duplicates
INSERT INTO employees (first_name, last_name, email, hire_date) values
('Emily', 'Davis', 'emilydavis@example.com', '2022-04-05'),
('Matthew', 'Martinez', 'matthewmartinez@example.com', '2022-01-10');


SELECT * FROM employees;

delete from employees where id in 
(
	select id  from
	(
	select id, row_number() over( partition by first_name , last_name order by id ) as 'rnk' from employees
	)k where rnk>1
);



-- 2  You sales manager and you have 3 territories under you,   the manager decided that for each territory the salesperson who have  sold more than 30%  of the average of that 
-- territory  will  get  hike  and person who have done 80% less than the average salary will be issued PIP , now for all you have to  tell your manager if he/she will 
-- get a hike or will be in a PIP

create table sales(  
    sales_person varchar(100),
    territory varchar(2),
    sales int 
);

INSERT INTO sales (sales_person, territory, sales)
VALUES ('John', 'A',40),
       ('Alice', 'A', 150),
       ('Michael', 'A', 200),
       ('Sarah', 'A', 120),
       ('Kevin', 'A', 180),
       ('Jessica', 'A', 90),
       ('David', 'A', 130),
       ('Emily', 'A', 140),
       ('Daniel', 'A', 270),
       ('Laura', 'A', 300),
       ('Jane', 'B', 180),
       ('Robert', 'B', 220),
       ('Mary', 'B', 190),
       ('Peter', 'B', 210),
       ('Emma', 'B', 130),
       ('Matthew', 'B', 140),
       ('Olivia', 'B', 170),
       ('William', 'B', 240),
       ('Sophia', 'B', 210),
       ('Andrew', 'B', 300),
       ('James', 'C', 300),
       ('Linda', 'C', 270),
       ('Richard', 'C', 320),
       ('Jennifer', 'C', 280),
       ('Charles', 'C', 250),
       ('Amanda', 'C', 290),
       ('Thomas', 'C', 260),
       ('Susan', 'C', 310),
       ('Paul', 'C', 280),
       ('Karen', 'C', 300);

select * from sales;

set @a= (select round(avg(sales),2) as average_a from sales where territory= 'A');
set @b= (select round(avg(sales),2) as average_b from sales where territory= 'B');
set @c= (select round(avg(sales),2) as average_c from sales where territory= 'C');

SELECT @a, @b, @c;

select *,
     case when sales>1.3*territory_mean  then  'HIKE'
          WHEN SALES <0.8*TERRITORY_MEAN then 'PIP'
	      else 'Same parameter'
		end as 'Final decision'
from (
	SELECT *,
		CASE WHEN territory = 'A' THEN @a
			 WHEN territory = 'B' THEN @b
			 WHEN territory = 'C' THEN @c
			 ELSE NULL
		END AS territory_mean
	FROM sales
)k;



-- 3. You are database administrator for a university , University have declared result for a special exam ,
--    However children were not happy with the marks as marks were not given appropriately and many students marksheet was
--    blank , so they striked. Due to strike univerisity again checked the sheets and updates were made.
--    Handle these updates

CREATE TABLE students(
	roll int ,
	s_name varchar(100),
	Marks  float
);

INSERT INTO students (roll, s_name, Marks)
VALUES (1, 'John', 75),
    (2, 'Alice', 55),
    (3, 'Bob', 40),
    (4, 'Sarah', 85),
    (5, 'Mike', 65),
    (6, 'Emily', 50),
    (7, 'David', 70),
    (8, 'Sophia', 45),
    (9, 'Tom', 55),
    (10, 'Emma', 80),
    (11, 'James', 58),
    (12, 'Lily', 72),
    (13, 'Andrew', 55),
    (14, 'Olivia', 62),
    (15, 'Daniel', 78);


CREATE TABLE std_updates(
  roll int,
  s_name varchar(100),
  marks float 
);

INSERT INTO std_updates (roll, s_name, Marks)
VALUES  (8, 'Sophia', 75),   -- existing
		(9, 'Tom', 85),
		(16, 'Grace', 55),     -- new
		(17, 'Henry', 72),
		(18, 'Sophie', 45),
		(19, 'Jack', 58),
		(20, 'Ella', 42);


-- updation done
update  students as s
inner join std_updates as t
set s.marks= t.marks
where s.roll= t.roll;

-- insertion of new data
INSERT INTO students (roll, s_name, marks)
SELECT  roll, s_name, marks
FROM (
    SELECT s.roll AS rl, t.*
    FROM students AS s
    RIGHT JOIN std_updates AS t ON s.roll = t.roll
) k
WHERE rl IS NULL;


Truncate table students

DELIMITER //
CREATE PROCEDURE ProcessUpdatesAndInserts()
BEGIN
    -- Update existing records
    UPDATE students AS s
    INNER JOIN std_updates AS t ON s.roll = t.roll
    SET s.marks = t.marks;

    -- Insert new records
    INSERT INTO students (roll, s_name, marks)
    SELECT roll, s_name, marks
    FROM (
        SELECT s.roll AS rl, t.*
        FROM students AS s
        RIGHT JOIN std_updates AS t ON s.roll = t.roll
    ) k
    WHERE rl IS NULL;

    -- Truncate the std_updates table
    TRUNCATE TABLE std_updates;
END //
DELIMITER ;


select * from students;
select * from std_updates;

call ProcessUpdatesAndInserts();



-- 4 You have  to make a procedure , where you will give 
--   3 inputs string, deliminator  and before and after  command , based on the   information provided you have to 
--   find that part of string.

DELIMITER //
create function string_split( s varchar(100), d varchar(5), c varchar (10))
returns Varchar(100)
DETERMINISTIC
begin
     set @l = length(d);  -- deliminator can be of any length.
     set @p = locate(d, s);
     set @o = 
        case  when c like '%before%'
            then left(s,@p)
        else 
            substring(s, @p+@l,length(s))
		end;
  return @o;
end //
DELIMITER ;



-- 5 You have a table that stores student information  roll number wise , now some of the students have left the
--   school due to which the  roll numbers became discontinuous
--   Now your task is to make them continuous.

DROP TABLE students;

-- creating table
CREATE TABLE students (
    roll_number INT PRIMARY KEY,
    name VARCHAR(50),
    marks DECIMAL(5, 2),
    favourite_subject VARCHAR(50)
);

-- inserting data
INSERT INTO students (roll_number, name, marks, favourite_subject) VALUES
    (1, 'Rahul Sharma', 75.5, 'Mathematics'),
    (2, 'Priya Patel', 82.0, 'Science'),
    (3, 'Amit Singh', 68.5, 'History'),
    (4, 'Sneha Reddy', 90.75, 'English'),
    (5, 'Vivek Gupta', 79.0, 'Physics'),
    (6, 'Ananya Desai', 85.25, 'Chemistry'),
    (7, 'Rajesh Verma', 72.0, 'Biology'),
    (8, 'Neha Mishra', 88.5, 'Computer Science'),
    (9, 'Arun Kumar', 76.75, 'Economics'),
    (10, 'Pooja Mehta', 94.0, 'Geography'),
	(11, 'Sanjay Gupta', 81.5, 'Mathematics'),
    (12, 'Divya Sharma', 77.0, 'Science'),
    (13, 'Rakesh Patel', 83.5, 'History'),
    (14, 'Kavita Reddy', 89.25, 'English'),
    (15, 'Ankit Verma', 72.0, 'Physics');

SET GLOBAL event_scheduler = ON;

-- Create the stored procedure to renumber students after delete
DELIMITER //
CREATE PROCEDURE renumber_students_after_delete()
BEGIN
    update  students as s                                                  -- step 2 and 3
	inner join
	(
	 select *, row_number() over ( order by roll_number) as roll from students 
	)k 
	on s.roll_number = k.roll_number 
	set s.roll_number = k.roll;
END//
DELIMITER ;


-- Create the event to renumber students every hour
DELIMITER //
CREATE EVENT IF NOT EXISTS renumber_students_event
ON SCHEDULE EVERY 20 second
DO
BEGIN
    CALL renumber_students_after_delete();
END//
DELIMITER ;

select * from students;

DELETE FROM students WHERE roll_number IN (3,5,9,13);



-- 6. create a system where it will check the warehouse before making the sale and if sufficient
--    quantity is avaibale make the sale and store the sales transaction 
--    else show error for insufficient quantity.( like an ecommerce website, before making final transaction look for stock.)

CREATE TABLE products(
  product_code varchar(20),
  product_name varchar(20),
  price int,
  Quantity_remaining int,
  Quantity_sold int
);
INSERT INTO products (product_code, product_name, price, Quantity_remaining, Quantity_sold)
VALUES
    ('RO001', 'Rolex Submariner', 7500, 20, 0),
    ('RO002', 'Rolex Datejust', 6000, 15, 0),
    ('RO003', 'Rolex Daytona', 8500, 25, 0),
    ('RO004', 'Rolex GMT-Master II', 7000, 18, 0),
    ('RO005', 'Rolex Explorer', 5500, 12, 0),
    ('RO006', 'Rolex Yacht-Master', 9000, 30, 0),
    ('RO007', 'Rolex Sky-Dweller', 9500, 22, 0);

DROP TABLE sales;
create table sales ( 
	order_id int auto_increment primary key,
	order_date date,
	product_code varchar(10),
	Quantity_sold int,
	per_quantity_price int,
	total_sale_price int
);


DELIMITER //
CREATE PROCEDURE MakeSale(IN pname VARCHAR(100),IN quantity INT)
BEGIN
    set @co = (select product_code from products where product_name= pname);
    set @qu = (select Quantity_remaining from products  where product_code= @co);
    set @pr = (select price from products where product_code= @co);
    IF quantity <=  @qu THEN
        INSERT INTO sales (order_date, product_code, Quantity_sold, per_quantity_price , total_sale_price)
        VALUES (CURRENT_DATE(), @co, quantity,@pr, quantity* @pr);
        SELECT 'Sale successful' AS message; -- Output success message
        update products
        set quantity_remaining = quantity_remaining - quantity,
            Quantity_sold= Quantity_sold+quantity
		where  product_name = pname;
	ELSE
        SELECT 'Insufficient quantity available' AS message;
    END IF;

END //
DELIMITER ;



call makesale ('Rolex Submariner', 4);
select * from sales;
select * from products;



-- 8. Given a Sales table containing SaleID, ProductID, SaleAmount, and SaleDate, write a SQL query to find the top 2
--    salespeople based on their total sales amount for the current month. If there's a tie in sales amount,
--    prioritize the salesperson with the earlier registration date.
DROP TABLE Sales;
CREATE TABLE Sales (
    Sale_man_registration_date date ,
    ProductID INT,
    SaleAmount DECIMAL(10, 2),
    SaleDate DATE,
    SalespersonID INT
);

-- Inserting Sample Data into the Sales Table
INSERT INTO Sales (Sale_man_registration_date, ProductID, SaleAmount, SaleDate, SalespersonID)
VALUES
    ('2023-07-15', 101, 150.00, '2023-07-05', 1),
    ('2023-07-15', 102, 200.00, '2023-07-10', 2),
    ('2023-07-15', 103, 180.00, '2023-07-15', 3),
    ('2023-07-15', 104, 220.00, '2023-07-20', 4),
    ('2023-07-15', 105, 190.00, '2023-07-25', 5),
    ('2023-07-15', 101, 210.00, '2023-08-05', 1),
    ('2023-07-15', 102, 180.00, '2023-08-10', 2),
    ('2023-07-15', 103, 200.00, '2023-08-15', 3),
    ('2023-07-15', 104, 190.00, '2023-08-20', 4),
    ('2023-07-15', 105, 220.00, '2023-08-25', 5),
    ('2024-01-10', 101, 230.00, '2024-01-05', 1),
    ('2024-01-10', 102, 190.00, '2024-01-10', 2),
    ('2024-01-10', 103, 220.00, '2024-01-15', 3),
    ('2024-01-10', 104, 190.00, '2024-01-20', 4),
    ('2024-01-10', 105, 230.00, '2024-01-25', 5),
    ('2024-01-10', 101, 240.00, '2024-02-05', 1),
    ('2024-01-10', 102, 180.00, '2024-02-10', 2),
    ('2024-01-10', 103, 220.00, '2024-02-15', 3),
    ('2024-01-10', 104, 200.00, '2024-02-20', 4),
    ('2024-01-10', 105, 210.00, '2024-02-25', 5),
    ('2024-04-15', 101, 250.00, '2024-04-05', 1),
    ('2024-04-15', 102, 200.00, '2024-04-10', 2),
    ('2024-04-15', 103, 180.00, '2024-04-15', 3),
    ('2024-04-15', 104, 220.00, '2024-04-20', 4),
    ('2024-04-15', 105, 220.00, '2024-04-25', 5),
    ('2024-04-15', 101, 210.00, '2024-05-05', 1),
    ('2024-04-15', 102, 180.00, '2024-05-10', 2),
    ('2024-04-15', 103, 200.00, '2024-05-15', 3),
    ('2024-04-15', 104, 190.00, '2024-05-20', 4),
    ('2024-04-15', 105, 220.00, '2024-05-25', 5);

SELECT salespersonId, sum(saleamount) AS summ, min(Sale_man_registration_date) as mindate
FROM sales WHERE YEAR(saledate)=2024 AND MONTH(saledate) = 4 GROUP BY salespersonid
ORDER BY summ DESC , mindate
LIMIT 0, 3;
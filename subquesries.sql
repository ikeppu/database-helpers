SELECT
    student_name
FROM
    Students
WHERE
    student_id IN (
        SELECT
            student_id
        FROM
            Exam_Results
        WHERE
            score > 92
    );

-- --------------------------------------------
SELECT
    Name,
    Salary
FROM
    Employees
WHERE
    Salary > (
        SELECT
            AVG(Salary)
        FROM
            Employees
    );

-- --------------------------------------------
SELECT
    Name,
    (
        SELECT
            COUNT(*)
        FROM
            Orders
        WHERE
            Orders.CustomerID = Customers.CustomerID
    ) as OrderCount
FROM
    Customers;
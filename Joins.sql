SELECT
    *
FROM
    table1
    INNER JOIN table2 ON table1.column_name = table2.column_name;

-- Self join example
SELECT
    t1.column_name,
    t2.column_name
FROM
    table_name t1
    JOIN table_name t2 ON t1.common_column = t2.common_column;
create database downtime_shield;
use downtime_shield;

-- total production per product 
SELECT Product, COUNT(*) AS total_batches
FROM manufacturing_data
GROUP BY Product
ORDER BY total_batches DESC;

-- which is the most common downtime issues 
SELECT 
    'Emergency_stop' AS issue, SUM(Emergency_stop) AS total FROM downtime2
UNION ALL
SELECT 'Machine_failure', SUM(Machine_failure) FROM downtime2
UNION ALL
SELECT 'Labeling_error', SUM(Labeling_error) FROM downtime2
UNION ALL
SELECT 'Inventory_shortage', SUM(Inventory_shortage) FROM downtime2
ORDER BY total DESC;




ALTER TABLE downtime2 CHANGE `total(m)` total_m INT;

-- which shift has the highest total downtime

SELECT manufacturing_data.shift, SUM(downtime2.total_m) AS total_downtime
FROM manufacturing_data 
JOIN downtime2  ON manufacturing_data.Batch = downtime2.Batch
GROUP BY manufacturing_data.shift
ORDER BY total_downtime DESC;


-- operator with best efficiency
SELECT operator2.operator, AVG(downtime2.total_m) AS avg_downtime_per_batch
FROM downtime2 
JOIN operator2  ON downtime2.operator_id = operator2.operatorid
GROUP BY operator2.operator
ORDER BY avg_downtime_per_batch ASC;

-- daily total production
SELECT Date, COUNT(Batch) AS total_batches
FROM manufacturing_data
GROUP BY Date
ORDER BY Date DESC;

ALTER TABLE manufacturing_data CHANGE `Duration(m)` Duration_m INT;

-- Find if longer production times result in more downtime

SELECT manufacturing_data.Duration_m, AVG(downtime2.total_m) AS avg_downtime
FROM manufacturing_data 
JOIN downtime2  ON manufacturing_data.Batch = downtime2.Batch
GROUP BY manufacturing_data.Duration_m
ORDER BY manufacturing_data.Duration_m;

--  Total Downtime per Product
SELECT product, SUM(total_m) AS total_downtime_minutes
FROM downtime2
GROUP BY product
ORDER BY total_downtime_minutes DESC;

-- downtime(non operator)
SELECT 'Emergency Stop' AS downtime_type, SUM(Emergency_stop) AS total_minutes, 'Non-Operator Error' AS error_category FROM downtime2
UNION ALL
SELECT 'Labeling Error', SUM(Labeling_error), 'Non-Operator Error' FROM downtime2
UNION ALL
SELECT 'Inventory Shortage', SUM(Inventory_shortage), 'Non-Operator Error' FROM downtime2
UNION ALL
SELECT 'Machine Failure', SUM(Machine_failure), 'Non-Operator Error' FROM downtime2
UNION ALL
SELECT 'Conveyor Belt Jam', SUM(Conveyor_belt_jam), 'Non-Operator Error' FROM downtime2
UNION ALL
SELECT 'Other', SUM(Other), 'Non-Operator Error' FROM downtime2
ORDER BY total_minutes DESC;

-- downtime(operator):
SELECT 'Batch Change', SUM(Batch_change), 'Operator Error' FROM downtime2
UNION ALL
SELECT 'Product Spill', SUM(Product_spill), 'Operator Error' FROM downtime2
UNION ALL
SELECT 'Machine Adjustment', SUM(Machine_adjustment), 'Operator Error' FROM downtime2
UNION ALL
SELECT 'Batch Coding Error', SUM(Batch_coding_error), 'Operator Error' FROM downtime2
UNION ALL
SELECT 'Calibration Error', SUM(Calibration_error), 'Non-Operator Error' FROM downtime2
UNION ALL
SELECT 'Label Switch', SUM(Label_switch), 'Operator Error' FROM downtime2
ORDER BY total_minutes DESC;

-- statistical analysis 

SELECT 
    AVG(Duration_m) AS average_value,
    MIN(Duration_m) AS min_value,
    MAX(Duration_m) AS max_value,
    SUM(Duration_m) AS total_sum
FROM manufacturing_data;


-- Relations :
-- batch as a composite key
ALTER TABLE downtime2 
ADD PRIMARY KEY (Batch);
ALTER TABLE downtime2
ADD FOREIGN KEY (Batch) REFERENCES manufacturing_data(Batch);

ALTER TABLE operator2
ADD PRIMARY KEY (operatorid);

ALTER TABLE manufacturing_data
ADD FOREIGN KEY (operator_id) REFERENCES operator2(operatorid);

CREATE TABLE operator_downtime (
	operatorid INT,
    Batch INT,
    PRIMARY KEY (operatorid , Batch),
    FOREIGN KEY (operatorid) REFERENCES operator2(operatorid),
    FOREIGN KEY (Batch) REFERENCES downtime2(Batch)
);



















create database downtime_shield;
use downtime_shield;
ALTER TABLE Manufacturing_data
ADD CONSTRAINT PK_Manufacturing PRIMARY KEY (Batch);

ALTER TABLE Operator
ADD CONSTRAINT PK_Operator PRIMARY KEY (operatorid);

ALTER TABLE Downtime
ADD CONSTRAINT PK_Downtime PRIMARY KEY (Batch);

ALTER TABLE batch_time
ADD CONSTRAINT PK_BatchTime PRIMARY KEY (Product);

ALTER TABLE Manufacturing_data
ADD CONSTRAINT FK_Manufacturing_Operator
FOREIGN KEY (operator_id) REFERENCES Operator(operatorid);

ALTER TABLE Downtime
ADD CONSTRAINT FK_Downtime_Operator
FOREIGN KEY (operator_id) REFERENCES Operator(operatorid);

ALTER TABLE Downtime
ADD CONSTRAINT FK_Downtime_Manufacturing
FOREIGN KEY (Batch) REFERENCES Manufacturing_data(Batch);
ALTER TABLE Manufacturing_data 
MODIFY COLUMN Product VARCHAR(100);

ALTER TABLE batch_time 
MODIFY COLUMN Product VARCHAR(100);
CREATE UNIQUE INDEX idx_Product_batch_time ON batch_time(Product);
ALTER TABLE Manufacturing_data
ADD CONSTRAINT FK_Manufacturing_BatchTime
FOREIGN KEY (Product) REFERENCES batch_time(Product);

-- manufacturing analysis:

-- 1. Total production per product
SELECT Product, COUNT(*) AS total_batches
FROM Manufacturing_data
GROUP BY Product
ORDER BY total_batches DESC;

-- 2. monthly total production
SELECT 
    DATE_FORMAT(STR_TO_DATE(Date, '%m/%d/%Y'), '%Y-%m') AS month,
    COUNT(Batch) AS total_batches
FROM 
    manufacturing_data
GROUP BY 
    DATE_FORMAT(STR_TO_DATE(Date, '%m/%d/%Y'), '%Y-%m')
ORDER BY 
    month;
-- 3. Shift with highest production
SELECT Shift, COUNT(Batch) AS total_batches
FROM Manufacturing_data
GROUP BY Shift
ORDER BY total_batches DESC;

-- 4.  production duration per product
SELECT Product, round(sum(Duration_h)) AS sum_duration_hours
FROM Manufacturing_data
GROUP BY Product
ORDER BY sum_duration_hours desc;


--  Production details with downtime
SELECT 
    m.Batch,
    m.Product,
    m.Shift,
    m.Duration_m AS production_duration,
    d.total_m AS downtime_minutes
FROM 
    Manufacturing_data m
JOIN 
    Downtime d ON m.Batch = d.Batch;


--  Full production view (all joins)
SELECT 
    m.Batch,
    m.Product,
    m.Shift,
    m.Date,
    m.Duration_m AS production_duration,
    d.total_m AS downtime_minutes,
    o.operator AS Operator
FROM 
    Manufacturing_data m
JOIN 
    Downtime d ON m.Batch = d.Batch
JOIN 
    Operator o ON m.operator_id = o.operatorid
JOIN 
    batch_time b ON m.Product = b.Product;
    
-- Downtime Data Analysis
-- Total downtime per operator-related reason
SELECT 'Batch change' AS reason, SUM(Batch_change/60) AS total_hours FROM downtime
UNION ALL
SELECT 'Product spill', round(SUM(Product_spill/60))FROM downtime
UNION ALL
SELECT 'Machine adjustment', round(SUM(Machine_adjustment/60)) FROM downtime
UNION ALL
SELECT 'Batch coding error', round(SUM(Batch_coding_error/60)) FROM downtime
UNION ALL
SELECT 'Calibration error', round(SUM(Calibration_error/60)) FROM downtime
UNION ALL
SELECT 'Label switch', round(SUM(Label_switch/60)) FROM downtime
ORDER BY total_hours DESC;
-- Total downtime per non-operator-related reason
SELECT 'Emergency stop' AS reason, round(SUM(Emergency_stop/60)) AS total_hours from downtime
UNION ALL
SELECT 'Labeling error',round( SUM(Labeling_error/60)) FROM downtime
UNION ALL
SELECT 'Inventory shortage', round(SUM(Inventory_shortage/60)) FROM downtime
UNION ALL
SELECT 'Machine failure', round(SUM(Machine_failure/60)) FROM downtime
UNION ALL
SELECT 'Conveyor belt jam', round(SUM(Conveyor_belt_jam/60)) FROM downtime
UNION ALL
SELECT 'Other', round(SUM(Other/60)) FROM downtime
ORDER BY total_hours desc ;

-- Operator-related downtime 
SELECT 
    d.Batch,
    o.operator AS Operator,
    d.operator_error AS total_downtime,
    d.Batch_change,
    d.Product_spill,
    d.Machine_adjustment,
    d.Batch_coding_error,
	d.Calibration_error,
	d.Label_switch,
    m.product
FROM 
    Downtime d
JOIN 
    Operator o ON d.operator_id = o.operatorid
JOIN 
    manufacturing_data m ON d.Batch = m.Batch  
WHERE 
    d.operator_error > 0  
order by  d.Batch;

-- non operator error :
SELECT 
    Batch,
    (total_m - operator_error) AS non_operator_downtime,
    Emergency_stop,
    Machine_failure,
    Labeling_error,
    Inventory_shortage,
    Conveyor_belt_jam,
    other
FROM 
    Downtime
WHERE (total_m - operator_error) > 0
ORDER BY batch;

-- Shift with highest total downtime
SELECT m.Shift, round(SUM(d.total_h)) AS total_downtime
FROM Downtime d
JOIN Manufacturing_data m ON d.Batch = m.Batch
GROUP BY m.Shift
ORDER BY total_downtime DESC;

--  Total downtime per month
SELECT 
    DATE_FORMAT(STR_TO_DATE(m.Date, '%m/%d/%Y'), '%Y-%m') AS month,
    ROUND(SUM(d.total_h)) AS total_downtime_hours
FROM 
    downtime d
JOIN 
    manufacturing_data m ON d.Batch = m.Batch
GROUP BY 
    DATE_FORMAT(STR_TO_DATE(m.Date, '%m/%d/%Y'), '%Y-%m')
ORDER BY 
    month;
    --  Total operator downtime per month
    SELECT 
    DATE_FORMAT(STR_TO_DATE(m.Date, '%m/%d/%Y'), '%Y-%m') AS month,
    round(SUM(d.operator_H)) AS total_operator_errors
FROM 
    downtime d
JOIN 
    manufacturing_data m ON d.Batch = m.Batch
WHERE 
    d.operator_error > 0
GROUP BY 
    DATE_FORMAT(STR_TO_DATE(m.Date, '%m/%d/%Y'), '%Y-%m')
ORDER BY 
    month;

-- Top 5 batches with highest downtime
SELECT d.Batch, d.total_m,m.product,o.operator
FROM Downtime d join manufacturing_data m 
on m.batch=d.batch
join operator o 
on d.operator_id = o.operatorid
ORDER BY total_m DESC
LIMIT 5;
-- sum downtime per product
SELECT m.Product, round(sum(d.total_h)) AS sum_downtime
FROM Downtime d
JOIN Manufacturing_data m ON d.Batch = m.Batch
GROUP BY m.Product
ORDER BY sum_downtime DESC;
SELECT 
    m.Product,
    FLOOR(SUM(m.Duration_h)) AS duration_h,
    FLOOR(SUM(d.total_h)) AS total_h
FROM 
    Manufacturing_data m
JOIN 
    Downtime d ON m.Batch = d.Batch
GROUP BY 
    m.Product
ORDER BY 
    duration_h DESC;
    
-- Operator Data Analysis:
--  Operator with most error
SELECT o.operator AS Operator, round(SUM(operator_h)) AS total_errors
FROM Downtime d
JOIN Operator o ON d.operator_id = o.operatorid
GROUP BY o.operator
ORDER BY total_errors DESC;
-- 3. Top 3 operators by least downtime most effecient :
SELECT o.operator AS Operator, round(sum(d.operator_h)) AS sum_downtime
FROM Downtime d
JOIN Operator o ON d.operator_id = o.operatorid
GROUP BY o.operator
ORDER BY sum_downtime ASC
LIMIT 3;
-- Batch Time Data Analysis:
-- 1. Batch time range per product-flavor-size
SELECT 
    Product,
    Flavor,
    Size,
    Max_batch_time - Min_batch_time AS batch_time_range
FROM 
    batch_time
ORDER BY 
    batch_time_range DESC;
-- highest  products:    
SELECT 
    Product,
    Flavor,
    Size,
    Max_batch_time
FROM 
    batch_time
ORDER BY 
    Max_batch_time desc;
-- lowest products :
SELECT 
    Product,
    Flavor,
    Size,
    Min_batch_time
FROM 
    batch_time
ORDER BY 
    Min_batch_time desc;









/* Bank Statement Analysis */

-- Creating Database
CREATE DATABASE Finance

USE Finance

-- Creating Schema
CREATE SCHEMA Bank

--Import Dataset

--View Datasets
SELECT *
FROM Bank.FirstBank;

SELECT *
FROM Bank.OPay;

--Sum of Credit Transactions
SELECT
	TransactionType, Details, SUM(Credit) Total_Credit
FROM
	Bank.FirstBank
WHERE
	TransactionType = 'Credit'
GROUP BY TransactionType, Details
ORDER BY Total_Credit;

--Sum of Debit Transactions
SELECT
	TransactionType, Details, SUM(Debit) Total_Debit
FROM
	Bank.FirstBank
WHERE
	TransactionType = 'Debit'
GROUP BY TransactionType, Details
ORDER BY Total_Debit;


--Sum of Credit Transactions
SELECT
	TransactionType, Details, SUM(Credit) Total_Credit
FROM
	Bank.OPay
WHERE
	TransactionType = 'Credit'
GROUP BY TransactionType, Details
ORDER BY Total_Credit;

--Sum of Debit Transactions
SELECT
	TransactionType, Details, SUM(Debit) Total_Debit
FROM
	Bank.OPay
WHERE
	TransactionType = 'Debit'
GROUP BY TransactionType, Details
ORDER BY Total_Debit;

--Filling the null values with zero for the Credit and Debit columns
SELECT Debit
FROM Bank.FirstBank
WHERE Debit IS NULL;

SELECT Debit
FROM Bank.OPay
WHERE Debit IS NULL;

UPDATE Bank.FirstBank
SET Credit = 0
WHERE Credit IS NULL;

UPDATE Bank.FirstBank
SET Debit = 0
WHERE Debit IS NULL;

UPDATE Bank.OPay
SET Debit = 0
WHERE Debit IS NULL;

UPDATE Bank.OPay
SET Debit = ABS(Debit);

--Replace "-" with 0 in the OPay Credit column
SELECT (CASE WHEN Credit < 0 THEN 0 ELSE Credit END) Credit
FROM Bank.OPay;

UPDATE Bank.OPay
SET Credit = CASE WHEN Credit < 0 THEN 0 ELSE Credit END;

--Rename the Balance column to TransactionAmount using stored procedures
EXEC sp_rename 
	'Bank.OPay.Balance', 'TransactionAmount', 'COLUMN';


--Add transaction amount column
ALTER TABLE Bank.FirstBank
ADD TransactionAmount float;

--Add values into the TransactionAmount column
UPDATE Bank.FirstBank
SET TransactionAmount = Credit + Debit

UPDATE Bank.OPay
SET TransactionAmount = Credit + Debit


--Check the maximum and minimum transaction dates
SELECT MAX(TransDate) Max_Date, MIN(TransDate) Min_Date
FROM Bank.FirstBank;

SELECT MAX(TransDate) Max_DateO, MIN(TransDate) Min_DateO
FROM Bank.OPay;


--Drop the ValueDate and TransactionDetails column, as it isn't needed
ALTER TABLE Bank.FirstBank
DROP COLUMN ValueDate, TransactionDetails;

ALTER TABLE Bank.OPay
DROP COLUMN ValueDate, TransactionDetails;

--Create a year, month and day column
SELECT 
	DATEPART(Year, TransDate) Year, DATENAME(Month, TransDate) Month,
	DATEPART(Month, TransDate) MonthNumber, DATEPART(Day, TransDate) Day
FROM Bank.FirstBank;

--Add the date columns into the date table
--Firstly, create new columns
ALTER TABLE Bank.FirstBank
ADD Year INT, Month VARCHAR(50), MonthNumber INT, Day INT;

ALTER TABLE Bank.OPay
ADD Year INT, Month VARCHAR(50), MonthNumber INT, Day INT;

--Update table
UPDATE Bank.FirstBank
SET 
	Year = DATEPART(Year, TransDate),
	Month = DATENAME(Month, TransDate),
	MonthNumber = DATEPART(Month, TransDate),
	Day = DATEPART(Day, TransDate);


UPDATE Bank.OPay
SET 
	Year = DATEPART(Year, TransDate),
	Month = DATENAME(Month, TransDate),
	MonthNumber = DATEPART(Month, TransDate),
	Day = DATEPART(Day, TransDate);


--Check for Total transactions by month
SELECT Month, SUM(TransactionAmount) TransactionAmonnt
FROM Bank.FirstBank
GROUP BY Month
ORDER BY 2 DESC;

SELECT Month, SUM(TransactionAmount) TransactionAmonnt
FROM Bank.OPay
GROUP BY Month
ORDER BY 2 DESC;

--Check Transactions based on Transaction type on each month
SELECT Month, TransactionType, SUM(TransactionAmount) TransactionAmount
FROM Bank.FirstBank
GROUP BY Month, TransactionType
ORDER BY 3;

SELECT Month, TransactionType, SUM(TransactionAmount) TransactionAmount
FROM Bank.OPay
GROUP BY Month, TransactionType
ORDER BY 3;

--Check Transactions based on Details on each month
SELECT Details, SUM(TransactionAmount) TransactionAmount
FROM Bank.FirstBank
GROUP BY Details
ORDER BY 2 DESC;

SELECT Details, SUM(TransactionAmount) TransactionAmount
FROM Bank.OPay
GROUP BY Details
ORDER BY 2 DESC;

--------------------------------------------------------------------------------------------------------------------------
--Net Profit
--Calculating using Subquery and CTE; still returns the same value

--Subquery
SELECT Month, (Total_credit - Total_debit) Net_profit
FROM
(
SELECT
	Month,
	SUM(CASE WHEN TransactionType = 'Credit' THEN TransactionAmount ELSE 0 END) Total_credit,
	SUM(CASE WHEN TransactionType = 'Debit' THEN TransactionAmount ELSE 0 END) Total_debit
FROM
	Bank.FirstBank
GROUP BY Month) AS Subquery;

--CTE
WITH TransactionSummary AS 
(
SELECT
	Month,
	SUM(CASE WHEN TransactionType = 'Credit' THEN TransactionAmount ELSE 0 END) TotalCredit,
	SUM(CASE WHEN TransactionType = 'Debit' THEN TransactionAmount ELSE 0 END) TotalDebit
FROM
	Bank.FirstBank
GROUP BY
	Month
)
SELECT 
	Month, (TotalCredit - TotalDebit) NetProfit
FROM 
	TransactionSummary
ORDER BY NetProfit DESC;

WITH TransactionSummary AS 
(
SELECT
	Month,
	SUM(CASE WHEN TransactionType = 'Credit' THEN TransactionAmount ELSE 0 END) TotalCredit,
	SUM(CASE WHEN TransactionType = 'Debit' THEN TransactionAmount ELSE 0 END) TotalDebit
FROM
	Bank.OPay
GROUP BY
	Month
)
SELECT 
	Month, (TotalCredit - TotalDebit) NetProfit
FROM 
	TransactionSummary
ORDER BY NetProfit DESC;

--Top 3 transaction types per month
SELECT TOP 4 Month, TransactionType, SUM(TransactionAmount) TransactionAmount
FROM Bank.FirstBank
GROUP BY Month, TransactionType
ORDER BY TransactionAmount DESC;

--Top 3 transaction types per month
SELECT TOP 4 Month, TransactionType, SUM(TransactionAmount) TransactionAmount
FROM Bank.OPay
GROUP BY Month, TransactionType
ORDER BY TransactionAmount DESC;

--Top 3 transactions with positive influence
SELECT
	DISTINCT TOP 3 FORMAT(CONVERT(DATETIME, TransDate), 'dd-MMM-yyyy') Date,
	SUM(CASE WHEN TransactionType = 'Credit' THEN TransactionAmount ELSE 0 END) Credit_Amount,
	SUM(CASE WHEN TransactionType = 'Debit' THEN TransactionAmount ELSE 0 END) Debit_Amount,
	SUM(CASE WHEN TransactionType = 'Credit' THEN TransactionAmount ELSE 0 END - 
		CASE WHEN TransactionType = 'Debit' THEN TransactionAmount ELSE 0 END) Net_Value
FROM
	Bank.FirstBank
GROUP BY
	TransDate
ORDER BY
	Net_Value DESC;

--Top 3 transactions with negative influence
SELECT
	DISTINCT TOP 3 FORMAT(CONVERT(DATETIME, TransDate), 'dd-MMM-yyyy') Date,
	SUM(CASE WHEN TransactionType = 'Credit' THEN TransactionAmount ELSE 0 END) Credit_Amount,
	SUM(CASE WHEN TransactionType = 'Debit' THEN TransactionAmount ELSE 0 END) Debit_Amount,
	SUM(CASE WHEN TransactionType = 'Credit' THEN TransactionAmount ELSE 0 END - 
		CASE WHEN TransactionType = 'Debit' THEN TransactionAmount ELSE 0 END) Net_Value
FROM
	Bank.FirstBank
GROUP BY
	TransDate
ORDER BY
	Net_Value ASC;


SELECT
	DISTINCT TOP 3 FORMAT(CONVERT(DATETIME, TransDate), 'dd-MMM-yyyy') Date,
	SUM(CASE WHEN TransactionType = 'Credit' THEN TransactionAmount ELSE 0 END) Credit_Amount,
	SUM(CASE WHEN TransactionType = 'Debit' THEN TransactionAmount ELSE 0 END) Debit_Amount,
	SUM(CASE WHEN TransactionType = 'Credit' THEN TransactionAmount ELSE 0 END - 
		CASE WHEN TransactionType = 'Debit' THEN TransactionAmount ELSE 0 END) Net_Value
FROM
	Bank.OPay
GROUP BY
	TransDate
ORDER BY
	Net_Value DESC;

--Top 3 transactions with negative influence
SELECT
	DISTINCT TOP 3 FORMAT(CONVERT(DATETIME, TransDate), 'dd-MMM-yyyy') Date,
	SUM(CASE WHEN TransactionType = 'Credit' THEN TransactionAmount ELSE 0 END) Credit_Amount,
	SUM(CASE WHEN TransactionType = 'Debit' THEN TransactionAmount ELSE 0 END) Debit_Amount,
	SUM(CASE WHEN TransactionType = 'Credit' THEN TransactionAmount ELSE 0 END - 
		CASE WHEN TransactionType = 'Debit' THEN TransactionAmount ELSE 0 END) Net_Value
FROM
	Bank.OPay
GROUP BY
	TransDate
ORDER BY
	Net_Value ASC;

--Count of transactions per month
SELECT [Month], COUNT(*) Transactions
FROM Bank.FirstBank
GROUP BY [Month]
ORDER BY Transactions;

SELECT [Month], COUNT(*) Transactions
FROM Bank.OPay
GROUP BY [Month]
ORDER BY Transactions;

--/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
--Create a View as our reference table for visualisation
CREATE VIEW [Statement] AS
SELECT
	CASE WHEN a.TransDate IS NULL THEN b.TransDate ELSE a.TransDate END AS TransDate, 
	COALESCE(a.Credit, b.Credit) Credit, COALESCE(a.Debit, b.Debit) [Debit], COALESCE(a.Bank, b.Bank) Bank,
	ISNULL(a.TransactionType, b.TransactionType) [TransactionType], ISNULL(a.Details, b.Details) [Details],
	COALESCE(a.TransactionAmount, b.TransactionAmount) [TransactionAmount]
FROM Bank.FirstBank a
FULL JOIN Bank.OPay b
ON a.TransDate = b.TransDate;

--Create a calendar view
CREATE VIEW [Calendar] AS
SELECT 
	ISNULL(a.TransDate, b.TransDate) TransDate, ISNULL(a.Year, b.Year) [Year],
	ISNULL(a.Month, b.Month) [Month], ISNULL(a.MonthNumber, b.MonthNumber) [MonthNum], ISNULL(a.Day, b.Day) [Day]
FROM Bank.FirstBank a
FULL JOIN Bank.OPay b
ON a.TransDate = b.TransDate;

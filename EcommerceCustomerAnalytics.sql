Create Database EcommerceCustomerAnalytics;

-- Check Row Count After Import
Select Count(*) As Rows_2009_2010 From dbo.[page 1];
Select Count(*) As Rows_2010_2011 From dbo.[page 2];

-- Combine Both Years And Convert Types Safely
Select Invoice, StockCode, Description, Quantity, CONVERT(VARCHAR(16),
	Coalesce(TRY_CONVERT(datetime2, InvoiceDate, 120), TRY_CONVERT(datetime2, InvoiceDate, 105)), 120) As InvoiceDate,
	TRY_CONVERT(decimal(10,2), price) As Price, Customer_ID, Country, '2009-2010' As SourceSheet
Into dbo.RetailCombined
From dbo.[page 1]
Union All
Select Invoice, StockCode, Description, Quantity, CONVERT(VARCHAR(16),
	Coalesce(TRY_CONVERT(datetime2, InvoiceDate, 120), TRY_CONVERT(datetime2, InvoiceDate, 105)), 120) As InvoiceDate,
	TRY_CONVERT(decimal(10,2), price) As Price, Customer_ID, Country, '2010-2011' As SourceSheet
From dbo.[page 2];

Select * from dbo.RetailCombined
	
-- Confirm The Conversion Worked Cleanly
Select Count(*) As Total_Rows From dbo.RetailCombined;
Select Count(*) As Failed_Dates From dbo.RetailCombined Where InvoiceDate Is Null;
Select Count(*) As Failed_Prices From dbo.RetailCombined Where Price Is Null;

-- Check 1 - Missing Customer ID
Select Count(*) As Missing_CustomerID From dbo.RetailCombined Where Customer_ID Is Null;

-- Check 2 - Negative Or Zero Quantity
Select Count(*) As Negative_Qty From dbo.RetailCombined Where Quantity <= 0;

-- Check 3 - Missing Description
Select Count(*) As Missing_Description From dbo.RetailCombined Where Description Is Null;

-- Check 4 - Exact Duplicate Rows
Select Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country, Count(*) As ExactDupeCount
From dbo.RetailCombined
Group By Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country Having Count(*) > 1;

-- Deduplicate And Produce The Final Cleaned Table
With Deduped As (Select *, Row_Number() Over (Partition By Invoice, StockCode, Description, Quantity, InvoiceDate, 
Price, Customer_ID, Country Order By (Select Null)) As RowNum From dbo.RetailCombined)
Select Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country, SourceSheet 
Into dbo.RetailCleaned From Deduped Where RowNum = 1;

Select * From dbo.RetailCleaned;


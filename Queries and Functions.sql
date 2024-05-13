/*Note:
Most of the queries and functions written here are performed on a database(Northwind) containing the following tables 
to demonstrate a products order system:
[Customers]([CustomerID], [CompanyName], [City], [Country]...),
[Employees]([EmployeeID], [FirstName], [LastName]...),
[Order Details]([OrderID], [ProductID], [UnitPrice], [Quantity], [Discount]),
[Orders]([OrderID], [CustomerID], [EmployeeID], [OrderDate], [ShippedDate]...),
[Products]([ProductID], [ProductName]...),

The tables linked as follows:
FOREIGN KEY(Orders.CustomerID) REFERENCES Customers(CustomerID)
FOREIGN KEY(Orders.EmployeeID) REFERENCES Employees(EmployeeID)
FOREIGN KEY([Order Details].ProductID) REFERENCES Products(ProductID)
FOREIGN KEY(Orders.OrderID) REFERENCES [Order Details](OrderID)*/

/*Query to retrieve a report showing the number of customers, number of orders, 
total sales of the largest order and last order date for countries - Belgium France Portugal and Spain*/
SELECT C.Country,
		COUNT(DISTINCT(C.CustomerID)) AS 'NumberOfCustomers',
		COUNT(DISTINCT(O.OrderID)) AS 'NumberOfOrders', 
		ROUND(MAX(OD.UnitPrice*OD.Quantity*(1-OD.Discount)),0) AS 'Largest single order',
		MAX(O.OrderDate) AS 'LastOrderDate'
from Orders AS O
JOIN Customers AS C
ON C.CustomerID = O.CustomerID
JOIN [Order Details] AS OD
ON O.OrderID = OD.OrderID
WHERE C.Country IN ('Belgium', 'France', 'Portugal', 'Spain')
GROUP BY C.Country
GO

---------------------------------------------------------
/*Query to retrieve a report showing the number of orders with a delivery date on Friday 
for each employee number and employee name, including a column with the percentage of the orders (on Friday) 
out of the total orders.*/
SELECT O.EmployeeID, E.FirstName + ' ' + E.LastName AS  'Full Name',
		COUNT(O.OrderID) AS 'Number of Orders',
	    ROUND(CAST((COUNT(O.OrderID)*100) AS float) /CAST((SELECT COUNT(*) 
						FROM Orders
						WHERE DATENAME(WEEKDAY, [ShippedDate]) = 'Friday') AS float),2) AS '% of Total Orders',
		DATENAME(WEEKDAY, [ShippedDate]) AS 'Shipped Date'
FROM Orders as O
JOIN Employees AS E
	ON O.EmployeeID = E.EmployeeID
WHERE DATENAME(WEEKDAY, [ShippedDate]) = 'Friday'
GROUP BY O.EmployeeID, E.FirstName + ' ' + E.LastName, DATENAME(WEEKDAY, [ShippedDate])
ORDER BY 3 DESC
GO

---------------------------------------------------------
--Function that gets a string and returns each time an additionl letter from it(i, it, itz...)
CREATE FUNCTION fn_name(@p_name NVARCHAR(40))
RETURNS NVARCHAR(100)
AS
BEGIN
	DECLARE @v_NameLen INT,
			@v_counter INT,
			@v_partname NVARCHAR(100)

	SET @v_NameLen = LEN(@p_name)
	SET @v_counter = 1
	SET @v_partname = ''

	WHILE @v_counter <= @v_NameLen
		BEGIN
			SET @v_partname += left(@p_name, @v_counter) + CHAR(10)
			SET @v_counter += 1
		END
	RETURN @v_partname
END
GO

--Funtion check
PRINT dbo.fn_name('itzik')
GO
---------------------------------------------------------
--Funtion that creates username based on the first name and the first letter of the last name
CREATE FUNCTION fn_UserNameCreator(@firstname NVARCHAR(20), @LASTNAME NVARCHAR(20))
RETURNS NVARCHAR(50)
AS 
BEGIN
	RETURN LOWER(@firstname + LEFT(@lastname,1))
END

GO
--Funtion that creates email - input: username
CREATE FUNCTION fn_Email_Creator(@username NVARCHAR(50))
RETURNS NVARCHAR(60)
AS 
BEGIN
	RETURN @username + '@gmail.com'
END

GO
--Both functions check by calling them on first and last names in employee table fields
SELECT [EmployeeID], dbo.fn_UserNameCreator([FirstName], [LastName]) as UserName,
	dbo.fn_Email_Creator(dbo.fn_UserNameCreator([FirstName], [LastName])) as Email
from [dbo].[Employees]
GO

---------------------------------------------------------
/*The purpose of this function is to display the number of customers who have placed 
orders for that product when receiving a product name*/ 
CREATE FUNCTION fn_ProductOrderCnt(@p_ProductName NVARCHAR(40))
RETURNS SMALLINT
AS
BEGIN
	DECLARE @v_prodcount SMALLINT
	SELECT @v_prodcount = COUNT(DISTINCT O.CustomerID)
	FROM Orders AS O
	JOIN [Order Details] AS OD
	ON O.OrderID = OD.OrderID
	WHERE OD.ProductID = (SELECT ProductID
							FROM Products
							WHERE ProductName = @p_ProductName)
	RETURN @v_prodcount
END
GO

--Function check
SELECT [ProductName], dbo.fn_ProductOrderCnt([ProductName]) AS 'Number Of Customers Orders'
from [dbo].[Products]

GO

---------------------------------------------------------
/*The purpose of the function is to return a table that will consolidate the information about the orderId 
that will be given.
The table contains the orderId, the name of the company that placed the order, 
the full name of the employee who created the order, the total amount paid 
and the date the order was created*/ 
CREATE FUNCTION fn_OrderInfo(@p_orderId INT)
RETURNS @fn_OrderInfoTable TABLE
	(OrderId INT,
		CompanyName NVARCHAR(40),
		EmployeeName NVARCHAR(30),
		TotalPayment MONEY,
		Orderdate VARCHAR(10))
AS
BEGIN
	INSERT INTO @fn_OrderInfoTable
	SELECT O.OrderID, C.CompanyName, (E.FirstName+' '+ E.LastName), 
			SUM(OD.[UnitPrice]*OD.[Quantity]*(1-OD.[Discount])),
			CONVERT(VARCHAR(10),O.OrderDate, 103)
	FROM Orders AS O
	JOIN Customers AS C
	ON C.CustomerID = O.CustomerID
	JOIN Employees AS E
	ON E.EmployeeID = O.EmployeeID
	JOIN [Order Details] AS OD
	ON OD.OrderID = O.OrderID
	WHERE O.OrderID = @p_orderId
	GROUP BY O.OrderID, C.CompanyName, (E.FirstName+' '+ E.LastName), O.OrderDate
RETURN
END

GO


--Function check
SELECT * FROM dbo.fn_OrderInfo(10746)
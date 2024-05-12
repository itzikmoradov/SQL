--Database and Schemas Creation
CREATE DATABASE Flowers;
GO
CREATE SCHEMA Contact;
GO
CREATE SCHEMA [Order];
GO
CREATE SCHEMA Stock;
GO

--Tables Creation
CREATE TABLE Stock.Flowers
(
	FlowerID INT IDENTITY(1, 1) PRIMARY KEY,
	FlowerName VARCHAR(20) NOT NULL,
	PricePerUnit MONEY NOT NULL,
	FlowersInStock INT NOT NULL
)
GO

CREATE TABLE Contact.Customers
(
	CustomerID INT IDENTITY(1, 1) PRIMARY KEY,
	FirstName VARCHAR(20) NOT NULL,
	LastName VARCHAR(20) NOT NULL,
	[Address] VARCHAR(20),
	Email VARCHAR(20) CONSTRAINT ck_emailcheck CHECK(Email LIKE '%@%') NOT NULL,
	JoinDate SMALLDATETIME DEFAULT GETDATE() NOT NULL
)
GO

CREATE TABLE [Order].Orders
(
	OrderID INT IDENTITY(1, 1) NOT NULL,
	OrderDate SMALLDATETIME DEFAULT GETDATE() NOT NULL,
	CustomerID INT,
	CONSTRAINT fk_CustomerID FOREIGN KEY(CustomerID)
	REFERENCES Contact.Customers(CustomerID),
	FlowerID INT,
	CONSTRAINT fk_FlowerID FOREIGN KEY(FlowerID)
	REFERENCES Stock.Flowers(FlowerID),
	Quantity INT NOT NULL
)
GO

--------------------------------------
--Tables Population
INSERT INTO Contact.Customers (FirstName, LastName, [Address], Email, JoinDate)
VALUES
  ('John', 'Smith', NULL, 'johns@email.com', '2022-05-05'),
  ('Jane', 'Doe', '456 Elm Street', 'janed@email.com', '2022-05-04'),
  ('Michael', 'Jones', '789 Oak Avenue', 'michaelj@email.com', '2022-05-03'),
  ('Sarah', 'Lee', NULL, 'sarahl@email.com', '2022-05-02'),
  ('David', 'Williams', '20 Beach Drive', 'davidw@email.com', '2022-05-01');
GO

INSERT INTO Stock.Flowers (FlowerName, PricePerUnit, FlowersInStock)
VALUES
  ('Rose', '$12.99', 100),
  ('Lilium', '$14.50', 75),
  ('Tulip', '$11.99', 50),
  ('Daffodils', '$13.99', 80),
  ('Pansies', '$15.50', 25);
GO

INSERT INTO [Order].Orders (OrderDate, CustomerID, FlowerID, Quantity)
VALUES
  ('2023-05-05', 1, 2, 2), 
  ('2023-05-04', 3, 1, 1), 
  ('2023-05-03', 2, 4, 3), 
  ('2023-05-02', 5, 3, 1), 
  ('2023-05-01', 4, 5, 2), 
  ('2023-04-30', 1, 1, 1),
  ('2023-04-29', 2, 3, 4), 
  ('2023-04-28', 3, 2, 1), 
  ('2023-04-27', 5, 4, 2), 
  ('2023-04-26', 4, 1, 3), 
  ('2023-04-25', 1, 5, 1), 
  ('2023-04-24', 3, 3, 2),
  ('2023-04-23', 2, 2, 4), 
  ('2023-04-22', 5, 1, 1), 
  ('2023-04-21', 4, 5, 2)

GO

--------------------------------------
--View for top 5 most selled flowers
CREATE VIEW top_flowers_view
AS
SELECT TOP 5 F.FlowerID, F.FlowerName, SUM(O.Quantity) AS Amount_Sold
FROM [Order].[Orders] AS O 
JOIN stock.Flowers AS F
  ON O.FlowerID = F.FlowerID
GROUP BY F.flowerid, F.FlowerName
ORDER BY Amount_Sold DESC
GO

-- Check view:
SELECT * FROM top_flowers_view
GO
--------------------------------------
--Stored Procedure for new order insertion
CREATE PROCEDURE sp_NewOrderInsertion
(@p_FirstName VARCHAR(20),
@p_LastName VARCHAR(20),
@p_Address VARCHAR(20),
@p_Email VARCHAR(20),
@p_FlowerName VARCHAR(20),
@p_Quantity INT,
@p_OrderID INT OUTPUT)
AS
BEGIN
	--Check if the desired quantity of flowers are available
	DECLARE @v_FlowersInStock int
	SET @v_FlowersInStock = (SELECT [FlowersInStock]
						FROM [Stock].[Flowers]
						WHERE [FlowerName] = @p_FlowerName)

	IF @p_Quantity > @v_FlowersInStock
		BEGIN
			PRINT CONCAT('There are only ', @v_FlowersInStock, ' ',@p_FlowerName,'s in stock. Please select different quantity')
			SET @p_OrderID= -1
		END
	--Continue with the order if there are enough flowers in stock
	ELSE
		BEGIN
			DECLARE @v_fname VARCHAR(20),
					@v_lname VARCHAR(20),
					@v_customerid int,
					@v_flowerid int

			--Checking if customer already exists in DB
			SELECT @v_fname=[FirstName]
			FROM [Contact].[Customers]
			WHERE [FirstName] = @p_FirstName AND [LastName] = @p_LastName

			--Inserting cutomer to DB if doesn't exist and creating CustomerId(identity constraint)
			IF @v_fname is null 
				BEGIN
					--Making sure to insert to the table names with capital first letter (although the DB is not case sensitive)
					SET @v_fname = CONCAT(UPPER(LEFT(@p_FirstName,1)),LOWER(RIGHT(@p_FirstName, LEN(@p_FirstName)-1)))
					SET @v_lname = CONCAT(UPPER(LEFT(@p_LastName,1)),LOWER(RIGHT(@p_LastName, LEN(@p_LastName)-1)))

					INSERT INTO [Contact].[Customers]
					([FirstName], [LastName], [Address], [Email], [JoinDate])
					VALUES (@v_fname, @v_lname, @p_Address, @p_Email, GETDATE())
				END

			--Establishing an order
			--The Orders table consists of:OrderID - IDENTITY CONSTRAINT, OrderDate, CustomerID, FlowerID, Quantity fields 
			SET @v_customerid = (SELECT [CustomerID]
									FROM [Contact].[Customers] 
									WHERE [FirstName] = @p_FirstName AND [LastName] = @p_LastName)
			SET @v_flowerid = (SELECT [FlowerID]
								FROM [Stock].[Flowers]
								WHERE [FlowerName] = @p_FlowerName)


			INSERT INTO [Order].[Orders] ([OrderDate], [CustomerID], [FlowerID], [Quantity])
			VALUES(GETDATE(), @v_customerid, @v_flowerid, @p_Quantity)

			-- Get the generated IDENTITY value to return as OUTPUT parameter
			SET @p_OrderID=@@identity

			--Updating new quantity in the flowers table
			UPDATE [Stock].[Flowers]
			SET [FlowersInStock] = [FlowersInStock] - @p_Quantity
			WHERE [FlowerID] = @v_flowerid

		END
END
GO

--Stored Procedures Check - Inserting a new order and getting the 'OrderId'
DECLARE @v_NewOrderId INT
EXEC sp_NewOrderInsertion 'Itzik', 'moradov', NULL, 'imoradov@gmail.com', 'Rose', 300, @v_NewOrderId OUTPUT
PRINT CONCAT(CHAR(13),'New order id is: ', @v_NewOrderId)
GO
--------------------------------------
--Multi-Statment Table Valued Function that gets customer id and present its name along with all the orders he made ordered by date.
CREATE FUNCTION fn_CustOrders
(@p_CustomerID INT)
RETURNS @fn_CustomerTable TABLE
	(CustomerID INT,
	CustmerName VARCHAR(50),
	OrderID INT,
    OrderDate SMALLDATETIME,
    FlowerName VARCHAR(20),
    Quantity INT)
AS
BEGIN
	IF @p_CustomerID NOT IN (SELECT [CustomerID]
								FROM [Contact].[Customers])
		BEGIN
			INSERT INTO @fn_CustomerTable(CustmerName)
			VALUES('No such cutomer')
		END
	ELSE
		BEGIN
			INSERT INTO @fn_CustomerTable
			SELECT C.CustomerID, CONCAT(C.FirstName, ' ', C.LastName), 
						O.OrderID, O.OrderDate, F.FlowerName, O.Quantity
			FROM [Order].[Orders] AS O 
			JOIN [Contact].[Customers] AS C
				ON O.CustomerID = C.CustomerID
			JOIN [Stock].[Flowers] AS F
				ON F.FlowerID = O.FlowerID  
			WHERE C.CustomerID = @p_CustomerID
		END
	RETURN
END
-- Test the function:
SELECT * FROM fn_CustOrders(1)
SELECT * FROM fn_CustOrders(3)
-- No such customer:
SELECT * FROM fn_CustOrders(999)


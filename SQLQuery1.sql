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
	Email VARCHAR(20) NOT NULL,
	JoinDate SMALLDATETIME NOT NULL
)
GO

CREATE TABLE [Order].Orders
(
	OrderID INT IDENTITY(1, 1) NOT NULL,
	OrderDate SMALLDATETIME NOT NULL,
	CustomerID INT,
	CONSTRAINT fk_CustomerID FOREIGN KEY(CustomerID)
	REFERENCES Contact.Customers(CustomerID),
	FlowerID INT,
	CONSTRAINT fk_FlowerID FOREIGN KEY(FlowerID)
	REFERENCES Stock.Flowers(FlowerID),
	Quantity INT NOT NULL
)
GO

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
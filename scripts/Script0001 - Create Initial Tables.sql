-- Script0001 - Create Initial Tables
-- Strategy: Additive-Only Migration

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customers]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Customers] (
        [CustomerId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [CustomerName] NVARCHAR(100) NOT NULL,
        [Email] NVARCHAR(255) NOT NULL,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE()
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_Customers_Email' AND object_id = OBJECT_ID(N'[dbo].[Customers]'))
BEGIN
    CREATE UNIQUE INDEX [IX_Customers_Email] ON [dbo].[Customers]([Email]);
END
GO

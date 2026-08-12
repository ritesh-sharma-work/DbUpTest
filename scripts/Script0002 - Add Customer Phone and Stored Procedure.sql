-- Script0002 - Add Customer Phone and Stored Procedure
-- Strategy: Additive-Only Migration

-- 1. Add new column (Additive change)
IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[Customers]') AND name = N'PhoneNumber'
)
BEGIN
    ALTER TABLE [dbo].[Customers] ADD [PhoneNumber] NVARCHAR(20) NULL;
END
GO

-- 2. Create Stored Procedure (Additive change)
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_GetCustomerByEmail]') AND type in (N'P', N'PC'))
BEGIN
    EXEC('
    CREATE PROCEDURE [dbo].[usp_GetCustomerByEmail]
        @Email NVARCHAR(255)
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT CustomerId, CustomerName, Email, PhoneNumber, CreatedAt
        FROM [dbo].[Customers]
        WHERE Email = @Email;
    END
    ');
END
GO

-- 3. Seed Reference Data (Additive change)
IF NOT EXISTS (SELECT 1 FROM [dbo].[Customers] WHERE Email = 'sample.user@example.com')
BEGIN
    INSERT INTO [dbo].[Customers] ([CustomerName], [Email], [PhoneNumber])
    VALUES ('Sample User', 'sample.user@example.com', '+1-555-0199');
END
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [etl].[DimCustomer_MasterLoad]

AS
BEGIN

-- Data Uploader
EXEC mdm.etl.LoadDimCustomer @ClientDB = 'Missouri', @LoadView = 'api.UploadDimCustomerStaging', @LogLevel = '2', @DropTemp = '1', @IsDataUploaderSource = '1'

-- SFDC Contact
EXEC MDM.etl.LoadDimCustomer @ClientDB = 'Missouri', @LoadView = '[etl].[vw_Load_DimCustomer_SFDCContact]', @LogLevel = '0', @DropTemp = '1', @IsDataUploaderSource = '0'

-- SFDC Account
EXEC MDM.etl.LoadDimCustomer @ClientDB = 'Missouri', @LoadView = '[etl].[vw_Load_DimCustomer_SFDCAccount]', @LogLevel = '0', @DropTemp = '1', @IsDataUploaderSource = '0'


UPDATE b
	SET b.IsDeleted = a.IsDeleted
	,deletedate = getdate()
	--SELECT a.IsDeleted
	--SELECT COUNT(*) 
	FROM Missouri_Reporting.ProdCopy.Account a 
	INNER JOIN dbo.DimCustomer b ON a.id = b.SSID AND b.SourceSystem = 'Mizzou PC_SFDC Account'
	WHERE a.IsDeleted <> b.IsDeleted


	UPDATE b
	SET b.IsDeleted = a.IsDeleted
	,deletedate = getdate()
	--SELECT a.IsDeleted
	--SELECT COUNT(*) 
	FROM Missouri_Reporting.ProdCopy.contact a 
	INNER JOIN dbo.DimCustomer b ON a.id = b.SSID AND b.SourceSystem = 'Mizzou PC_SFDC Contact'
	WHERE a.IsDeleted <> b.IsDeleted


	UPDATE dimcustomer SET customer_matchkey = 'TM-' + SSID
	WHERE SourceSystem = 'tm' AND CustomerType = 'primary'

END







GO

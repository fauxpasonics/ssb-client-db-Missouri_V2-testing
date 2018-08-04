SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [api].[CRM_GetDonations] --@SSB_CRMSYSTEM_CONTACT_ID = '374146CF-9801-4153-8649-D6376D53042A'
    @SSB_CRMSYSTEM_ACCT_ID VARCHAR(50) = 'Test',
	@SSB_CRMSYSTEM_CONTACT_ID VARCHAR(50) = 'Test',
	@DisplayTable INT = 0,
	@RowsPerPage  INT = 500,
	@PageNumber   INT = 0,
	@ViewResultInTable INT = 0
AS

BEGIN

-- Init vars needed for API
DECLARE @totalCount         INT,
	@xmlDataNode        XML,
	@recordsInResponse  INT,
	@remainingCount     INT,
	@rootNodeName       NVARCHAR(100),
	@responseInfoNode   NVARCHAR(MAX),
	@finalXml           XML
	--,@SSB_CRMSYSTEM_CONTACT_ID VARCHAR(50) = '374146CF-9801-4153-8649-D6376D53042A',
	--@SSB_CRMSYSTEM_ACCT_ID VARCHAR(50) = 'Test',
	--@RowsPerPage  INT = 500,
	--@PageNumber   INT = 0,
	--@ViewResultInTable INT = 0
	
	--DROP TABLE #customerids
	--DROP TABLE #patronlist
	--DROP TABLE #tmpa
	--DROP TABLE #returnset
	--DROP TABLE #topgroup


DECLARE @GUIDTable TABLE (
GUID VARCHAR(50)
)

IF (@SSB_CRMSYSTEM_ACCT_ID NOT IN ('None','Test'))
BEGIN
	INSERT INTO @GUIDTable
	        ( GUID )
	SELECT DISTINCT z.SSB_CRMSYSTEM_CONTACT_ID
		FROM dbo.vwDimCustomer_ModAcctId z 
		WHERE z.SSB_CRMSYSTEM_ACCT_ID = @SSB_CRMSYSTEM_ACCT_ID
END

IF (@SSB_CRMSYSTEM_CONTACT_ID NOT IN ('None','Test'))
BEGIN
	INSERT INTO @GUIDTable
	        ( GUID )
	SELECT @SSB_CRMSYSTEM_CONTACT_ID
END


-- Cap returned results at 1000
IF @RowsPerPage > 1000
BEGIN
	SET @RowsPerPage = 1000;
END


SELECT DISTINCT
	'MIzzou' AS Team
	, don.acct_id AS Account
	, CAST(don.pledge_datetime AS DATE) AS Pledge_Date
	, don.order_num AS Order_Number
	, don.order_line_item AS Order_Line_Item
	, don.donation_type_name AS Donation_Type
	, don.fund_name AS Fund_Name
	, don.fund_desc AS Fund_Description
	, don.drive_year AS Drive_Year
	, don.gl_code AS GL_Code
	, don.solicitation_name AS Solicitation_Name
	, don.solicitation_category_name AS Solicitation_Category
	, don.contact_type AS Contact_Type
	, don.original_pledge_amount AS Original_Pledge_Amount
	, don.pledge_amount AS Pledge_Amount
	, don.total_received_amount AS Total_Received_Amount
	, don.owed_amount AS Owed_Amount
	, don.external_paid_amount AS External_Paid_Amount
	, don.donor_level_amount_qual AS Donor_Level_Amount_Qual
	, don.donor_level_amount_not_qual AS Donor_Level_Amount_Not_Qual
	, don.[source] AS Donation_Source
	, don.points AS Points
	, don.donor_level_set_name AS Donor_Level_Set
INTO #tmpA
FROM ods.TM_Donation don (NOLOCK)
	JOIN dbo.vwDimCustomer_ModAcctId dc ON dc.AccountId = don.acct_id
	JOIN @GUIDTable gt ON gt.GUID = dc.SSB_CRMSYSTEM_CONTACT_ID
WHERE dc.SourceSystem = 'tm'




 SET @totalCount = @@ROWCOUNT
 
SELECT  Team
	, Account
	, a.Pledge_Date
	, a.Order_Number
	, a.Order_Line_Item
	, a.Donation_Type
	, a.Fund_Name
	, a.Fund_Description
	, a.Drive_Year
	, a.GL_Code
	, a.Solicitation_Name
	, a.Solicitation_Category
	, a.Contact_Type
	, a.Original_Pledge_Amount
	, a.Pledge_Amount
	, a.Total_Received_Amount
	, a.Owed_Amount
	, a.External_Paid_Amount
	, a.Donor_Level_Amount_Qual
	, a.Donor_Level_Amount_Not_Qual
	, a.Donation_Source
	, a.Points
	, a.Donor_Level_Set
INTO #ReturnSet
FROM #tmpA a
ORDER BY Pledge_Date DESC, Fund_Name
OFFSET (@PageNumber) * @RowsPerPage ROWS
FETCH NEXT @RowsPerPage ROWS ONLY

--SELECT * FROM [#ReturnSet]

SET @recordsInResponse  = (SELECT COUNT(*) FROM #ReturnSet)

SELECT Fund_Description
, Drive_Year
, SUM(Pledge_Amount) as Pledge_Amount_Total 
, SUM(Owed_Amount) as Owed_Amount_Total
, SUM(Total_Received_Amount) as Received_Amount_Total
INTO #TopGroup
FROM #ReturnSet
GROUP BY Fund_Description, Drive_Year
ORDER BY Drive_Year DESC

-- Create XML response data node
SET @xmlDataNode = (
SELECT    t.Fund_Description
		, FORMAT(Pledge_Amount_Total, 'C', 'en-us')		Pledge_Amount_Total
		, FORMAT(Owed_Amount_Total, 'C', 'en-us')		Owed_Amount_Total
		, FORMAT(Received_Amount_Total, 'C', 'en-us')	Received_Amount_Total
		, (SELECT [a].Account
				, a.Fund_Name
				, a.Pledge_Date
				, FORMAT(Original_Pledge_Amount		, 'C', 'en-us')		Original_Pledge_Amount
				, FORMAT(Pledge_Amount				, 'C', 'en-us')		Pledge_Amount
				, FORMAT(Total_Received_Amount		, 'C', 'en-us')		Total_Received_Amount
				, FORMAT(Owed_Amount				, 'C', 'en-us')		Owed_Amount
				, FORMAT(External_Paid_Amount		, 'C', 'en-us')		External_Paid_Amount
				, FORMAT(Donor_Level_Amount_Qual	, 'C', 'en-us')		Donor_Level_Amount_Qual
				, FORMAT(Donor_Level_Amount_Not_Qual, 'C', 'en-us')		Donor_Level_Amount_Not_Qual
				, a.Order_Number
				, a.Order_Line_Item
				, a.Fund_Description
				, a.Drive_Year
				, a.GL_Code
				, a.Solicitation_Name
				, a.Solicitation_Category
				, a.Contact_Type
				, a.Donation_Source
				, CAST(a.Points AS NUMERIC(18,2)) Points
				, a.Donor_Level_Set
			FROM [#ReturnSet] a 
			WHERE a.[Fund_Description] = t.Fund_Description AND a.Drive_Year = t.Drive_Year
			FOR XML PATH ('Child'), TYPE
			) AS 'Children'
FROM #topgroup AS t
ORDER BY t.Drive_Year DESC
FOR XML PATH ('Parent'), ROOT('Parents')
)


SET @rootNodeName = 'Parents'

-- Calculate remaining count
SET @remainingCount = @totalCount - (@RowsPerPage * (@PageNumber + 1))
IF @remainingCount < 0
BEGIN
	SET @remainingCount = 0
END

-- Wrap response info and data, then return	
IF @xmlDataNode IS NULL
BEGIN
	SET @xmlDataNode = '<' + @rootNodeName + ' />' 
END


-- Create response info node
SET @responseInfoNode = ('<ResponseInfo>'
	+ '<TotalCount>' + CAST(@totalCount AS NVARCHAR(20)) + '</TotalCount>'
	+ '<RemainingCount>' + CAST(@remainingCount AS NVARCHAR(20)) + '</RemainingCount>'
	+ '<RecordsInResponse>' + CAST(@recordsInResponse AS NVARCHAR(20)) + '</RecordsInResponse>'
	+ '<PagedResponse>true</PagedResponse>'
	+ '<RowsPerPage>' + CAST(@RowsPerPage AS NVARCHAR(20)) + '</RowsPerPage>'
	+ '<PageNumber>' + CAST(@PageNumber AS NVARCHAR(20)) + '</PageNumber>'
	+ '<RootNodeName>' + @rootNodeName + '</RootNodeName>'
	+ '</ResponseInfo>')

SET @finalXml = '<Root>' + @responseInfoNode + CAST(@xmlDataNode AS NVARCHAR(MAX)) + '</Root>'

IF ISNULL(@ViewResultinTable,0) = 0
BEGIN
SELECT CAST(@finalXml AS XML)
END
ELSE 
BEGIN
SELECT * FROM [#ReturnSet]
END

DROP TABLE [#tmpA]
DROP TABLE [#ReturnSet]
DROP TABLE [#TopGroup]
--DROP TABLE [#SecGroup]

END










GO

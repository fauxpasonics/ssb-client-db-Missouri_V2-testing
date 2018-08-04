SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












CREATE PROCEDURE [api].[CRM_GetDonations_bkp]  --'A3BFF14F-C863-4F17-96DD-C062E918F802'--@SSB_CRMSYSTEM_CONTACT_ID = '5CCF3E47-D8A9-41EC-A3CA-5DFA4C19552A',  @RowsPerPage = 500, @PageNumber = 0
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
	--@SSB_CRMSYSTEM_CONTACT_ID VARCHAR(50) = '0A96B64A-86EE-4389-8B3B-A47B5A35D586',
	--@SSB_CRMSYSTEM_ACCT_ID VARCHAR(50) = 'Test',
	--@RowsPerPage  INT = 500,
	--@PageNumber   INT = 0
	
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


DECLARE @PatronID VARCHAR(MAX)



-- Cap returned results at 1000
IF @RowsPerPage > 1000
BEGIN
	SET @RowsPerPage = 1000;
END

SELECT DimCustomerId INTO #CustomerIDs
FROM dbo.[vwDimCustomer_ModAcctId] dc WITH(NOLOCK)
WHERE ISNULL(dc.SSB_CRMSYSTEM_ACCT_ID, dc.SSB_CRMSYSTEM_CONTACT_ID)  = @SSB_CRMSYSTEM_ACCT_ID
OR ISNULL(dc.SSB_CRMSYSTEM_ACCT_ID, dc.SSB_CRMSYSTEM_CONTACT_ID)  = @SSB_CRMSYSTEM_CONTACT_ID
--'4E361DD3-6DF1-4C15-ACAE-1A4692086575'

IF @@ROWCOUNT = 0
BEGIN
	INSERT INTO #CustomerIDs
	SELECT dimcustomerid FROM mdm.SSB_ID_History a   WITH (NOLOCK)
	INNER JOIN dbo.[vwDimCustomer_ModAcctId] b  WITH (NOLOCK)
	ON a.ssid = b.ssid AND a.sourcesystem = b.SourceSystem
	WHERE ISNULL(a.SSB_CRMSYSTEM_ACCT_ID, a.SSB_CRMSYSTEM_CONTACT_ID) = @SSB_CRMSYSTEM_ACCT_ID
	OR ISNULL(a.SSB_CRMSYSTEM_ACCT_ID, a.SSB_CRMSYSTEM_CONTACT_ID)  = @SSB_CRMSYSTEM_CONTACT_ID
	;

END

--SELECT * FROM [#CustomerIDs]


SELECT DISTINCT a.[Accountid] 
INTO #PatronList
FROM dbo.[vwDimCustomer_ModAcctId] (nolock) a
INNER JOIN #CustomerIDs b ON a.DimCustomerId = b.DimCustomerId
WHERE a.SourceSystem = 'TM'
--AND a.SSID = '27182'
--AND b.SSB_CRMSYSTEM_CONTACT_ID = '56EB030F-2BE8-4C8F-A153-AF2A949C13B1'
-- DROP TABLE [#PatronList]

--SELECT * FROM [#PatronList]
--DECLARE @PatronID INT
SET @PatronID = (SELECT SUBSTRING(
(SELECT CONCAT(',',s.accountID)
FROM [#PatronList] s
ORDER BY s.Accountid
FOR XML PATH('')),2,200000) AS CSV)

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
WHERE don.acct_id IN (SELECT * FROM #PatronList)




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

--SELECT Campaign Campaign
--, Campaign_Name
--, Drive
--, SUM(PLG_AMT) as Pledge_Total 
--, SUM(CASH_AMT) as Cash_Total
--, SUM(BALANCE) as Balance
--INTO #Secgroup
--FROM #ReturnSet
--GROUP BY Campaign, campaign_name, Drive


-- Create XML response data node
SET @xmlDataNode = (
--SELECT [ParentValue] Season , [ParentLabel] AS [Season_Name]
--, CASE WHEN SIGN(ISNULL([AggregateValue] ,'')) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS([AggregateValue])), '0.00') AS [Order_Value],
--CASE WHEN SIGN(ISNULL([AggregateValue1] ,'')) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS([AggregateValue1])), '0.00') AS [Order_Balance],
SELECT t.Fund_Description
, CASE WHEN SIGN(ISNULL(t.Pledge_Amount_Total ,0)) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS(t.[Pledge_Amount_Total])), '0.00') as Pledge_Amount_Total_
, CASE WHEN SIGN(ISNULL(t.Owed_Amount_Total ,0)) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS([t].Owed_Amount_Total)), '0.00') as Owed_Amount_Total_
, CASE WHEN SIGN(ISNULL(t.Received_Amount_Total ,0)) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS([t].Received_Amount_Total)), '0.00') as Received_Amount_Total_
, (
--SELECT Campaign_Name
--, CASE WHEN SIGN(ISNULL(s.Pledge_Total ,0)) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS(s.[Pledge_Total])), '0.00') Pledge_Total
--, CASE WHEN SIGN(ISNULL(s.Cash_Total ,0)) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS(s.[Cash_Total])), '0.00') Cash_Total
--, CASE WHEN SIGN(ISNULL(s.Balance ,0)) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS(s.[Balance])), '0.00') Balance
--, (

	SELECT [a].Account
	, a.Fund_Name
	, a.Pledge_Date
	, CASE WHEN SIGN(ISNULL([a].[Original_Pledge_Amount] ,0)) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS( [a].[Original_Pledge_Amount])), '0.00') Original_Pledge_Amount
	, CASE WHEN SIGN(ISNULL([a].Pledge_Amount ,0)) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS( [a].[Pledge_Amount])), '0.00') Pledge_Amount
	, CASE WHEN SIGN(ISNULL([a].[Total_Received_Amount] ,0)) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS( [a].[Total_Received_Amount])), '0.00') Total_Received_Amount
	, CASE WHEN SIGN(ISNULL([a].[Owed_Amount] ,0)) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS( [a].[Owed_Amount])), '0.00') Owed_Amount
	, CASE WHEN SIGN(ISNULL([a].[External_Paid_Amount] ,0)) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS( [a].[External_Paid_Amount])), '0.00') External_Paid_Amount
	, CASE WHEN SIGN(ISNULL([a].[Donor_Level_Amount_Qual] ,0)) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS( [a].[Donor_Level_Amount_Qual])), '0.00') Donor_Level_Amount_Qual
	, CASE WHEN SIGN(ISNULL([a].[Donor_Level_Amount_Not_Qual] ,0)) <0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS( [a].[Donor_Level_Amount_Not_Qual])), '0.00') Donor_Level_Amount_Not_Qual
	, a.Order_Number
	, a.Order_Line_Item
	, a.Fund_Description
	, a.Drive_Year
	, a.GL_Code
	, a.Solicitation_Name
	, a.Solicitation_Category
    , a.Contact_Type
	, a.Donation_Source
	, a.Points
	, a.Donor_Level_Set
FROM [#ReturnSet] a 
WHERE a.[Fund_Description] = t.Fund_Description AND a.Drive_Year = t.Drive_Year
--FOR XML PATH ('Infant'), TYPE) AS 'Infants'
--FROM #secgroup AS s 
--WHERE s.campaign = t.campaign
FOR XML PATH ('Child'), TYPE) AS 'Children'
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
DROP TABLE [#CustomerIDs]
DROP TABLE [#PatronList]
DROP TABLE [#TopGroup]
--DROP TABLE [#SecGroup]

END










GO

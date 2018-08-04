SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE PROCEDURE [api].[CRM_GetRegistryView]
 @SSB_CRMSYSTEM_ACCT_ID VARCHAR(50) = 'Test',
 @SSB_CRMSYSTEM_CONTACT_ID VARCHAR(50) = 'Test',
	@DisplayTable INT = 0,
	@RowsPerPage  INT = 500, @PageNumber   INT = 0
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




SELECT * INTO #tmpBase
FROM (
SELECT  CASE WHEN @SSB_CRMSYSTEM_ACCT_ID NOT IN ('None', 'Test') THEN @SSB_CRMSYSTEM_ACCT_ID
	ELSE @SSB_CRMSYSTEM_CONTACT_ID END AS SourceSystemID ,
        'SSB Composite Record' AS SourceSystem ,
        FirstName ,
        LastName ,
        MiddleName ,
        AddressPrimaryStreet ,
        AddressPrimarySuite ,
        AddressPrimaryCity ,
        AddressPrimaryState ,
        AddressPrimaryZip ,
        PhonePrimary ,
        EmailPrimary ,
        CASE WHEN @SSB_CRMSYSTEM_ACCT_ID NOT IN ('None', 'Test') THEN @SSB_CRMSYSTEM_ACCT_ID
	ELSE @SSB_CRMSYSTEM_CONTACT_ID END AS SSBGUID ,
        0 AS IsPrimary ,
        1 AS IsComposite ,
        dc.CustomerType ,
        NULL AS customer_matchkey ,
        NULL AS ContactGUID ,
        dc.SSB_CRMSYSTEM_ACCT_ID ,
        dc.CD_Gender AS Gender ,
        dc.CompanyName
FROM    mdm.compositerecord dc ( NOLOCK )
WHERE   ContactGUID IN (SELECT GUID FROM @GUIDTable)
UNION
SELECT  SSID AS SourceSystemID ,
        SourceSystem ,
        FirstName ,
        LastName ,
        MiddleName ,
        AddressPrimaryStreet ,
        AddressPrimarySuite ,
        AddressPrimaryCity ,
        AddressPrimaryState ,
        AddressPrimaryZip ,
        PhonePrimary ,
        EmailPrimary ,
        CASE WHEN @SSB_CRMSYSTEM_ACCT_ID NOT IN ('None', 'Test') THEN @SSB_CRMSYSTEM_ACCT_ID
	ELSE @SSB_CRMSYSTEM_CONTACT_ID END AS SSBGUID ,
        ds.SSB_CRMSYSTEM_PRIMARY_FLAG AS IsPrimary ,
        0 AS IsComposite ,
        dc.CustomerType ,
        dc.customer_matchkey ,
        dc.ContactGUID ,
        SSB_CRMSYSTEM_ACCT_ID ,
        dc.CD_Gender AS Gender ,
        dc.CompanyName
FROM    DimCustomer dc
        JOIN ( SELECT   DimCustomerId ,
                        SSB_CRMSYSTEM_PRIMARY_FLAG ,
                        SSB_CRMSYSTEM_ACCT_ID
               FROM     dimcustomerssbid  (NOLOCK)
               WHERE    SSB_CRMSYSTEM_CONTACT_ID IN (SELECT GUID FROM @GUIDTable)
             ) ds ON dc.DimCustomerId = ds.DimCustomerId) x

SELECT 
  ISNULL(CAST(SourceSystemID AS VARCHAR(50)),'')	SourceSystemID
, ISNULL(SourceSystem				,'')	SourceSystem
, ISNULL(FirstName					,'')	FirstName
, ISNULL(LastName					,'')	LastName
, ISNULL(MiddleName					,'')	MiddleName
, ISNULL(AddressPrimaryStreet,'')+' '+ISNULL(AddressPrimarySuite,'')+ ' '+ISNULL(AddressPrimaryCity,'')+', '+ ISNULL(AddressPrimaryState,'')+ ' '+ ISNULL(AddressPrimaryZip,'') FullAddress
, ISNULL(PhonePrimary,'')	PhonePrimary
, ISNULL(EmailPrimary,'')	EmailPrimary
, ISNULL(CAST(SSBGUID AS VARCHAR(50)),'')	SSBGUID
, CASE WHEN ISNULL(IsPrimary,'') = 1 THEN 'Yes' WHEN ISNULL(IsPrimary,'') = 0 THEN 'NO' ELSE NULL END AS 	IsPrimary
, ISNULL(IsComposite,'')	IsComposite
, ISNULL(CustomerType,'')	CustomerType
, ISNULL(customer_matchkey,'')	Customer_Matchkey
, ISNULL(CAST(ContactGUID AS VARCHAR(50)),'')  AS ContactGUID
, ISNULL(CAST(SSB_CRMSYSTEM_ACCT_ID AS VARCHAR(50)),'')	SSB_CRMSYSTEM_ACCT_ID
, ISNULL(Gender, '') AS Gender
, ISNULL(CompanyName,'') AS CompanyName
INTO #tmpOutput
FROM #tmpBase
ORDER BY LastName DESC
OFFSET (@PageNumber) * @RowsPerPage ROWS
FETCH NEXT @RowsPerPage ROWS ONLY

-- Pull counts
SELECT @recordsInResponse = COUNT(*) FROM #tmpOutput
SELECT @totalCount = COUNT(*) FROM #tmpBase

SET @xmlDataNode = (
		SELECT * FROM #tmpOutput
		FOR XML PATH ('Parent'), ROOT('Parents'))

SET @rootNodeName = 'Parents'

-- Calculate remaining count
SET @remainingCount = @totalCount - (@RowsPerPage * (@PageNumber + 1))
IF @remainingCount < 0
BEGIN
	SET @remainingCount = 0
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

	PRINT @responseInfoNode
	
-- Wrap response info and data, then return	
IF @xmlDataNode IS NULL
BEGIN
	SET @xmlDataNode = '<' + @rootNodeName + ' />' 
END
		
SET @finalXml = '<Root>' + @responseInfoNode + CAST(@xmlDataNode AS NVARCHAR(MAX)) + '</Root>'

IF @DisplayTable = 1
SELECT * FROM #tmpBase

IF @DisplayTable = 0
SELECT CAST(@finalXml AS XML)

DROP TABLE #tmpBase
DROP TABLE #tmpOutput

 END








GO

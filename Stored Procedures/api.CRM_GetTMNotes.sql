SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE  [api].[CRM_GetTMNotes]
 @SSB_CRMSYSTEM_ACCT_ID VARCHAR(50) = 'None',
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


--DECLARE @SSB_CRMSYSTEM_ACCT_ID VARCHAR(50) = 'None'
--DECLARE @SSB_CRMSYSTEM_CONTACT_ID VARCHAR(50) = 'A508BD60-0C22-4077-AB74-E38FC2285A57'
--DECLARE	@RowsPerPage  INT = 500, @PageNumber   INT = 0
--DECLARE @DisplayTable INT = 0



--PRINT 'Acct-' + @SSB_CRMSYSTEM_ACCT_ID
--PRINT 'Contact-' + @SSB_CRMSYSTEM_CONTACT_ID

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
		SELECT DISTINCT z.SSB_CRMSYSTEM_CONTACT_ID
		FROM dbo.vwDimCustomer_ModAcctId z 
		WHERE z.SSB_CRMSYSTEM_CONTACT_ID = @SSB_CRMSYSTEM_CONTACT_ID
END




SELECT * INTO #tmpBase
FROM (
SELECT dc.SSB_CRMSYSTEM_CONTACT_ID
, n.acct_id
, n.add_user
, n.add_datetime
, n.upd_user
, n.upd_Datetime
, n.note_type
, n.task_Type
, n.category
, n.[subject]
, n.[text]
, n.task_activity
, n.task_result
, n.task_stage_status
, n.task_stage_text
, n.task_assigned_to_user_id
FROM [ods].[TM_Note] n (NOLOCK)
INNER JOIN [dbo].[vwDimCustomer_ModAcctId] dc ON dc.SourceSystem = 'TM' AND n.acct_id = dc.AccountId AND CustomerType = 'Primary'
WHERE note_type IN ('M', 'T')
--AND text NOT LIKE '%REPRINT Tickets%'
--AND text NOT LIK] 'Archtics Address Updated%'
AND  SSB_CRMSYSTEM_CONTACT_ID IN (SELECT GUID FROM @GUIDTable)
)x

SELECT 
  --ISNULL(SSB_CRMSYSTEM_CONTACT_ID								,'')	SSB_CRMSYSTEM_CONTACT_ID
 ISNULL(acct_id												,'')	TM_AccountId
, ISNULL(add_user												,'')	add_user
, ISNULL(add_datetime											,'')	add_datetime
, ISNULL(upd_user												,'')	upd_user
, ISNULL(upd_Datetime											,'')	upd_datetime
, ISNULL(note_type												,'')	note_type
, ISNULL(task_type												,'')	task_type
, ISNULL(category												,'')	[category]
, ISNULL([subject]												,'')	[subject]
, ISNULL([text]													,'')	[text]
, ISNULL(task_activity											,'')	task_activity
, ISNULL(task_result		 									,'')	task_result
, ISNULL(task_stage_status		 								,'')	task_stage_status
, ISNULL(task_stage_text	 									,'')	task_stage_text
, ISNULL(task_assigned_to_user_id	 							, '')	task_assigned_to_user_id
INTO #tmpOutput
FROM #tmpBase
ORDER BY upd_Datetime DESC
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

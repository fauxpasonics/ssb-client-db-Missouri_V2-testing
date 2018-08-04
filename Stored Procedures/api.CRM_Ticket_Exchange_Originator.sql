SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










--EXEC [api].[CRM_Ticket_Exchange_Originator] @SSB_CRMSYSTEM_ACCT_ID = '817086D0-27F0-40D2-84F0-41D9626B1E30'
--EXEC [api].[CRM_Ticket_Exchange_Originator] @SSB_CRMSYSTEM_CONTACT_ID = '	3DA5B3FC-6810-4C15-8F8A-17424FE1FED7', @DisplayTable = 0

CREATE PROCEDURE [api].[CRM_Ticket_Exchange_Originator] 
    @SSB_CRMSYSTEM_ACCT_ID VARCHAR(50) = 'Test',
	@SSB_CRMSYSTEM_CONTACT_ID VARCHAR(50) = 'Test',
	@DisplayTable INT = 0,
	@RowsPerPage  INT = 500, @PageNumber   INT = 0
--WITH RECOMPILE
AS 

BEGIN
/*
DECLARE @SSB_CRMSYSTEM_CONTACT_ID AS VARCHAR(50), @RowsPerPage  INT = 500, @PageNumber   INT = 0, @DisplayTable INT = 1
SET @SSB_CRMSYSTEM_CONTACT_ID = '94B615C4-C182-409B-82C9-0A12BB879567'
--EXEC [api].[CRM_Ticket_Exchange_Originator] @SSB_CRMSYSTEM_CONTACT_ID = '817086D0-27F0-40D2-84F0-41D9626B1E30', @DisplayTable = 0
*/

-- Init vars needed for API
DECLARE @totalCount     INT,
	@xmlDataNode        XML,
	@recordsInResponse  INT,
	@remainingCount     INT,
	@rootNodeName       NVARCHAR(100),
	@responseInfoNode   NVARCHAR(MAX),
	@finalXml           XML

PRINT 'Acct-' + @SSB_CRMSYSTEM_ACCT_ID
PRINT 'Contact-' + @SSB_CRMSYSTEM_CONTACT_ID

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

        SELECT ssbid.SSB_CRMSYSTEM_CONTACT_ID AS SSB_CRMSYSTEM_CONTACT_ID
			  --, DimCustomer.AccountId AS O_Archtics_Acct_Id
			  , Tex.activity AS O_Activity
			  , Tex.activity_name AS O_Activity_Name
			  , CAST(Tex.add_datetime AS DATE) AS O_Transaction_Date 
              , Tex.season_year AS O_Season_Year
              , Tex.event_name AS O_Event_Code
			  , Event.Team AS O_Event_Name 
              , Tex.event_time AS O_Event_Time
              , Tex.event_date AS O_Event_Date
              , Tex.section_name AS O_Section_Name
              , Tex.row_name AS O_Row_Name
              , Tex.seat_num AS O_First_Seat
              --, Tex.last_seat AS O_Last_Seat
              , Tex.num_seats AS O_Qty_Seat
              , CASE WHEN ISNUMERIC(Tex.Orig_purchase_price) = 0 THEN 0 ELSE
					CAST(Tex.Orig_purchase_price AS NUMERIC (18,2) )  * Tex.num_seats END AS O_Orig_purchase_price
              , CASE WHEN ISNUMERIC(Tex.te_purchase_price) = 0 THEN 0 ELSE CAST(Tex.te_purchase_price AS NUMERIC) END AS O_TE_Purchase_Price
			  , CASE WHEN ISNUMERIC(Tex.te_purchase_price) = 0 THEN 0 ELSE CAST(Tex.te_purchase_price AS NUMERIC) END - CASE WHEN ISNUMERIC(Tex.Orig_purchase_price) = 0 THEN 0 ELSE
					  CAST(Tex.Orig_purchase_price AS NUMERIC) * Tex.num_seats END  AS O_TE_Price_Difference
			  , tex.assoc_acct_id AS O_Recipient_Account_Id
		INTO #tmpBase
        FROM    ods.TM_Tex Tex
                INNER JOIN dbo.DimCustomer DimCustomer WITH ( NOLOCK ) ON DimCustomer.AccountId = Tex.acct_id AND DimCustomer.CustomerType = 'Primary' AND DimCustomer.SourceSystem = 'TM'
                INNER JOIN dbo.dimcustomerssbid ssbid WITH ( NOLOCK ) ON ssbid.DimCustomerId = DimCustomer.DimCustomerId
				INNER JOIN ods.TM_Evnt Event WITH ( NOLOCK ) ON Event.Event_id = Tex.event_id
        WHERE   Tex.activity_name = 'TE Resale'
			AND ssbid.SSB_CRMSYSTEM_CONTACT_ID IN (SELECT GUID FROM @GUIDTable)
			--AND tex.event_date >= DATEADD(YEAR, -2, GETDATE()+120)

-- Pull total count
SELECT @totalCount = COUNT(*) FROM #tmpBase

-- Load base data
SELECT 
--ISNULL(O_Activity,'') Activity
  ISNULL(O_Activity_Name,'') Activity_Name
, ISNULL(CONVERT(DATE,O_Transaction_Date,102),'') Transaction_Date
, ISNULL(O_Recipient_Account_Id,0) Buyer_Account_Id
, ISNULL(O_Season_Year,'') Season_Year	
, ISNULL(O_Event_Code,'') Event_Code	
, ISNULL(O_Event_Name,'') Event_Name	
--, ISNULL(O_Event_Time,'') Event_Time	
--, ISNULL(CONVERT(DATE,O_Event_Date,102),'') Event_Date	
, ISNULL(O_Section_Name,'') Section_Name	
, ISNULL(O_Row_Name,'') Row_Name	
--, ISNULL(O_First_Seat,'') First_Seat	
, ISNULL(O_Qty_Seat,'') Qty_Seat
, CASE WHEN SIGN(O_Orig_purchase_price)<0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS(O_Orig_purchase_price)), '0.00') AS Orig_purchase_price
, CASE WHEN SIGN(O_TE_Purchase_Price)<0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS(O_TE_Purchase_Price	)), '0.00') AS TE_Sold_Price		
, CASE WHEN SIGN(O_TE_Price_Difference)<0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS(O_TE_Price_Difference)), '0.00') as TE_Price_Difference
INTO #tmpOutput
FROM #tmpBase
ORDER BY O_Season_Year DESC, O_Transaction_Date Desc
OFFSET (@PageNumber) * @RowsPerPage ROWS
FETCH NEXT @RowsPerPage ROWS ONLY

--SELECT * FROM #tmpBase
SELECT O_Season_Year Season_Year
, Sum(O_Qty_Seat) Total_Qty_Sold
, CASE WHEN SIGN(SUM(O_Orig_purchase_price))<0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS( CAST(SUM(O_Orig_purchase_price) AS DECIMAL(18,2)))), '0.00') AS Total_Orig_purchase_price
, CASE WHEN SIGN(SUM(O_TE_Purchase_Price))<0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS( CAST(SUM(O_TE_Purchase_Price) AS DECIMAL(18,2) ))), '0.00') AS Total_TE_sold_Price
, CASE WHEN SIGN(SUM(O_TE_Purchase_Price)-SUM(O_Orig_purchase_price))<0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS( CAST(SUM(O_TE_Purchase_Price)-SUM(O_Orig_purchase_price) AS DECIMAL(18,2) ))), '0.00') AS Total_TE_Price_Difference
INTO #tmpParent
FROM #tmpBase
GROUP BY O_Season_Year 
-- DROP TABLE #tmpParent

SET @xmlDataNode = (
		SELECT * ,
			(
			SELECT Activity_Name
				   ,Transaction_Date
				   ,Buyer_Account_Id
				   --,Season_Year
				   ,Event_Code
				   ,Event_Name
				   ,Section_Name
				   ,Row_Name
				   ,Qty_Seat
				   ,Orig_purchase_price
				   ,TE_Sold_Price
				   ,TE_Price_Difference
			FROM #tmpOutput a
			WHERE a.Season_Year = p.Season_Year
				ORDER BY a.Transaction_Date
			FOR XML PATH ('Child'), TYPE
			) AS 'Children'                
		FROM #tmpParent p
		ORDER BY p.Season_Year DESC
		FOR XML PATH ('Parent'), ROOT('Parents'))

SET @rootNodeName = 'Parents'

-- Set records in response
--SELECT @recordsInResponse = COUNT(*) FROM @baseData
SELECT @recordsInResponse = COUNT(*) FROM #tmpBase

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

	
-- Wrap response info and data, then return	
IF @xmlDataNode IS NULL
BEGIN
	SET @xmlDataNode = '<' + @rootNodeName + ' />' 
END
		
SET @finalXml = '<Root>' + @responseInfoNode + CAST(@xmlDataNode AS NVARCHAR(MAX)) + '</Root>'

IF @DisplayTable = 1
BEGIN
	SELECT  *
	FROM    #tmpBase;

	SELECT  * ,
			( SELECT    *
			  FROM      #tmpOutput a
			  WHERE     a.Season_Year = p.Season_Year
			  ORDER BY  a.Season_Year DESC ,
						a.Event_Date DESC
			FOR
			  XML PATH('Child') ,
				  TYPE
			) AS 'Children'
	FROM    #tmpParent p
	ORDER BY p.Season_Year DESC
	FOR     XML PATH('Parent') ,
				ROOT('Parents');
END

IF @DisplayTable = 0
SELECT CAST(@finalXml AS XML)


DROP TABLE #tmpBase
DROP TABLE #tmpOutput
DROP TABLE #tmpParent
--DROP TABLE [#XMLFriendly]
END
















GO

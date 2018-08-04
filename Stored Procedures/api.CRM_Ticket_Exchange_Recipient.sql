SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










-- =============================================
-- Created By: 
-- Create Date: 
-- Reviewed By: Scott Sales
-- Reviewed Date: 2018-04-24
-- Description: Ticketmaster Exchange Recipient API Viewer
-- =============================================
 
/***** Revision History
 
2018-04-12 Abbey Meitin added 'Forward' to where clause


2018-04-24 Scott Sales confirmed logic/tested API viewer. All set.
*****/
 




CREATE PROCEDURE [api].[CRM_Ticket_Exchange_Recipient] 
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

/*
DECLARE @SSB_CRMSYSTEM_CONTACT_ID VARCHAR(50) = '0C0981FA-F3C5-4D9C-B626-258B77C1F8F6'
DECLARE	@RowsPerPage  INT = 500, @PageNumber   INT = 0
DECLARE @DisplayTable INT = 0
*/


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

        SELECT  ssbid.SSB_CRMSYSTEM_CONTACT_ID AS SSB_CRMSYSTEM_CONTACT_ID
			  --, DimCustomer.AccountId AS R_Archtics_Acct_Id
			  --, Tex.activity AS R_Activity
			  , Tex.activity_name AS R_Activity_Name
			  , CAST(Tex.add_datetime AS DATE) AS R_Transaction_Date 
              , Tex.season_year AS R_Season_Year
              , Tex.event_name AS R_Event_Code
			  , Event.Team AS R_Event_Name 
              --, Tex.event_time AS R_Event_Time
              , Tex.event_date AS R_Event_Date
              , Tex.section_name AS R_Section_Name
              , Tex.row_name AS R_Row_Name
              --, Tex.seat_num AS R_First_Seat
              --, Tex.last_seat AS R_Last_Seat
              , Tex.num_seats AS R_Qty_Seat
              , CASE WHEN ISNUMERIC(Tex.Orig_purchase_price) = 0 THEN 0 ELSE
					CAST(Tex.Orig_purchase_price AS NUMERIC (18,2) )  * Tex.num_seats END AS R_Orig_purchase_price
              , CASE WHEN ISNUMERIC(Tex.te_purchase_price) = 0 THEN 0 ELSE CAST(Tex.te_purchase_price AS NUMERIC) END AS R_TE_Purchase_Price
			  , CASE WHEN ISNUMERIC(Tex.te_purchase_price) = 0 THEN 0 ELSE CAST(Tex.te_purchase_price AS NUMERIC) END - CASE WHEN ISNUMERIC(Tex.Orig_purchase_price) = 0 THEN 0 ELSE
					  CAST(Tex.Orig_purchase_price AS NUMERIC) * Tex.num_seats END  AS R_TE_Price_Difference
			  , Tex.owner_acct_id AS R_Seller_Account_Id
		INTO #tmpBase
        FROM    ods.TM_Tex Tex
                INNER JOIN dbo.DimCustomer DimCustomer WITH ( NOLOCK ) ON DimCustomer.AccountId = Tex.assoc_acct_id AND DimCustomer.CustomerType = 'Primary' AND DimCustomer.SourceSystem = 'TM'
                INNER JOIN dbo.dimcustomerssbid ssbid WITH ( NOLOCK ) ON ssbid.DimCustomerId = DimCustomer.DimCustomerId
				INNER JOIN ods.TM_Evnt Event WITH ( NOLOCK ) ON Event.Event_id = Tex.event_id
        WHERE   Activity_Name IN ('TE Resale', 'Forward')
			AND ssbid.SSB_CRMSYSTEM_CONTACT_ID IN (SELECT GUID FROM @GUIDTable)
			--AND tex.event_date >= DATEADD(YEAR, -2, GETDATE()+120)
		ORDER BY R_Season_Year, Event.event_date


SELECT 
ISNULL(R_Activity_Name	    ,'')	  Activity_Name	  
, ISNULL(R_Transaction_Date		,'')  Transaction_Date		
, ISNULL(R_Season_Year			,'')  Season_Year			
, ISNULL(R_Event_Code			,'')  Event_Code			
, ISNULL(R_Event_Name			,'')  Event_Name			
, ISNULL(R_Event_Date			,'')  Event_Date			
, ISNULL(R_Section_Name			,'')  Section_Name			
, ISNULL(R_Row_Name				,'')  Row_Name				
, ISNULL(R_Qty_Seat				,'')  Qty_Seat				
, CASE WHEN SIGN(R_Orig_purchase_price)<0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),CAST(ABS(R_Orig_purchase_price	) AS DECIMAL(18,2))), '0.00')  Orig_purchase_price
, CASE WHEN SIGN(R_TE_Purchase_Price)<0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),CAST(ABS(R_TE_Purchase_Price	) AS DECIMAL(18,2))), '0.00')  TE_Purchase_Price	
, CASE WHEN SIGN(R_TE_Price_Difference)<0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),CAST(ABS(R_TE_Price_Difference	) AS DECIMAL(18,2))), '0.00')  TE_Price_Difference
, ISNULL(R_Seller_Account_Id, 0) Seller_Account_Id
INTO #tmpOutput
FROM #tmpBase
ORDER BY R_Event_Date DESC
OFFSET (@PageNumber) * @RowsPerPage ROWS
FETCH NEXT @RowsPerPage ROWS ONLY
--SELECT * FROM #tmpOutput
--DROP TABLE #tmpOutput

--SELECT * FROM #tmpBase
SELECT R_Season_Year Season_Year
, Sum(R_Qty_Seat) Total_Qty_Bought
, CASE WHEN SIGN(SUM(R_Orig_purchase_price))<0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS( CAST(SUM(R_Orig_purchase_price) AS DECIMAL(18,2)))), '0.00') AS Total_Orig_purchase_price
, CASE WHEN SIGN(SUM(R_TE_Purchase_Price))<0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS( CAST(SUM(R_TE_Purchase_Price) AS DECIMAL(18,2) ))), '0.00') AS Total_TE_Purchase_Price
, CASE WHEN SIGN(SUM(R_TE_Purchase_Price)-SUM(R_Orig_purchase_price))<0 THEN '-' ELSE '' END + '$' + ISNULL(CONVERT(VARCHAR(12),ABS( CAST(SUM(R_TE_Purchase_Price)-SUM(R_Orig_purchase_price) AS DECIMAL(18,2) ))), '0.00') AS Total_TE_Price_Difference
INTO #tmpParent
FROM #tmpBase
GROUP BY R_Season_Year 
-- DROP TABLE #tmpParent

-- Pull counts
SELECT @recordsInResponse = COUNT(*) FROM #tmpOutput
SELECT @totalCount = COUNT(*) FROM #tmpBase

SET @xmlDataNode = (
		SELECT * ,
			(
            SELECT  a.Activity_Name ,
                    a.Transaction_Date ,
					a.Seller_Account_Id,
                    --a.Season_Year ,
                    a.Event_Code ,
                    a.Event_Name ,
                    --a.Event_Date ,
                    a.Section_Name ,
                    a.Row_Name ,
                    a.Qty_Seat ,
                    a.Orig_purchase_price ,
                    a.TE_Purchase_Price ,
                    a.TE_Price_Difference
            FROM    #tmpOutput a
            WHERE   a.Season_Year = p.Season_Year
            ORDER BY a.Season_Year DESC ,
                    a.Event_Date DESC
            FOR     XML PATH('Child') ,
                        TYPE
			) AS 'Children'                
		FROM #tmpParent p
		ORDER BY p.Season_Year DESC
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
DROP TABLE #tmpParent






END
















GO

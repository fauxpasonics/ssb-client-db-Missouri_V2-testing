SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [api].[CRM_Primary_Ticketing_Transactions_DEV]
    @SSB_CRMSYSTEM_ACCT_ID VARCHAR(50) = 'Test',
	@SSB_CRMSYSTEM_CONTACT_ID VARCHAR(50) = 'Test',
	@DisplayTable INT = 0,
	@RowsPerPage  INT = 500, 
	@PageNumber   INT = 0
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
	 --  ,@SSB_CRMSYSTEM_ACCT_ID VARCHAR(50) = 'Test',
		--@SSB_CRMSYSTEM_CONTACT_ID VARCHAR(50) = 'Test',
		--@DisplayTable INT = 0,
		--@RowsPerPage  INT = 500, 
		--@PageNumber   INT = 0
	/*
DECLARE @SSB_CRMSYSTEM_CONTACT_ID VARCHAR(50) = '8F98286C-7875-42C1-91BD-196B3A64A112'
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


SELECT    DimSeason.SeasonName									AS Season_Name
        , CAST(DimDate.CalDate AS DATE)                         AS Order_Date   
        , DimSeason.SeasonYear                                  AS Season_Year
        , DimEvent.EventCode                                    AS Event_Code
        , DimEvent.EventName                                    AS Event_Name
        , DimEvent.EventDate                                    AS Event_Date
        , DimPriceCode.PriceCode                                AS Price_Code
        , DimItem.ItemCode										AS Item_Code
        , ISNULL(DimTicketType.TicketTypeName, 'UNCLASSIFIED')  AS Ticket_Type_Name
        , DimSeat.SectionName                                   AS Section_Name
        , DimSeat.RowName										AS Row_Name
        , fts.QtySeat											AS Qty_Seat
        , fts.BlockPurchasePrice                                AS Block_Purchase_Price
        , fts.PaidAmount										AS Paid_Amount
        , fts.OwedAmount										AS Owed_Amount
		, AccountRep.FirstName + ' ' + AccountRep.LastName      AS Sales_Rep
INTO #tmpBase
FROM dbo.FactTicketSales fts (NOLOCK)
	JOIN dbo.DimPriceCode DimPriceCode (NOLOCK) ON DimPriceCode.DimPriceCodeId = fts.DimPriceCodeId
	LEFT JOIN dbo.DimTicketType DimTicketType (NOLOCK) ON DimTicketType.DimTicketTypeId = fts.DimTicketTypeId
	JOIN dbo.DimCustomer AccountRep (NOLOCK) ON AccountRep.DimCustomerId = fts.DimCustomerIdSalesRep
	JOIN dbo.DimDate DimDate (NOLOCK) ON DimDate.DimDateId = fts.DimDateId
	JOIN dbo.DimSeason DimSeason (NOLOCK) ON DimSeason.DimSeasonId = fts.DimSeasonId
	JOIN dbo.DimEvent DimEvent (NOLOCK) ON DimEvent.DimEventId = fts.DimEventId
	JOIN dbo.dimcustomerssbid ssbid (NOLOCK) ON ssbid.DimCustomerId = fts.DimCustomerId
	JOIN dbo.DimSeat DimSeat (NOLOCK) ON DimSeat.DimSeatId = fts.DimSeatIdStart
	JOIN dbo.DimItem DimItem (NOLOCK) ON DimItem.DimItemId = fts.DimItemId
	JOIN @GUIDTable id ON id.GUID = ssbid.SSB_CRMSYSTEM_CONTACT_ID
WHERE DimSeason.SeasonYear >= 2014
	  AND DimSeason.PrevSeasonId IS NOT NULL
      AND fts.BlockPurchasePrice > 0


SELECT 
Season_Name
, ISNULL(Order_Date					,'')		AS Order_Date
, ISNULL(Season_Year				,'')		AS Season_Year
, ISNULL(Event_Code					,'')		AS Event_Code
, ISNULL(Event_Name					,'')		AS Event_Name
, ISNULL(Price_Code					,'')		AS Price_Code
, ISNULL(Item_Code					,'')		AS Item_Code
, ISNULL(Ticket_Type_Name			,'')		AS Ticket_Type_Name
, ISNULL(Section_Name				,'')		AS Section_Name
, ISNULL(Row_Name					,'')		AS Row_Name
, ISNULL(Qty_Seat		 			,'')		AS Qty_Seat
, FORMAT(Block_Purchase_Price, 'C', 'en-us')	AS Block_Purchase_Price
, FORMAT(Paid_Amount, 'C', 'en-us')				AS Paid_Amount
, FORMAT(Owed_Amount, 'C', 'en-us')				AS Owed_Amount
, ISNULL(Sales_Rep,'')							AS Sales_Rep
INTO #tmpOutput
FROM #tmpBase
ORDER BY ORDER_DATE DESC
OFFSET (@PageNumber) * @RowsPerPage ROWS
FETCH NEXT @RowsPerPage ROWS ONLY


SELECT 
Season_Name
,Season_Year
, FORMAT(SUM(Paid_Amount), 'C', 'en-us')											Paid_Amount
, FORMAT(SUM(Block_Purchase_Price), 'C', 'en-us')									Order_Value
, FORMAT(ISNULL(1.0*SUM(Paid_Amount) / NULLIF(SUM(Block_Purchase_Price),0),0),'p')	Paid
INTO #tmpParent
FROM #tmpBase
GROUP BY Season_Name
	    ,Season_Year

-- Pull counts
SELECT @recordsInResponse = COUNT(*) FROM #tmpOutput
SELECT @totalCount = COUNT(*) FROM #tmpBase

SET @xmlDataNode = (
		SELECT Season_Name
			   Paid_Amount ,
			   Order_Value ,
			   Paid ,
			(
            SELECT  a.Order_Date ,
					a.Ticket_Type_Name ,
                    a.Item_Code ,
                    a.Event_Code ,
                    a.Event_Name ,
                    a.Price_Code ,
                    a.Section_Name ,
                    a.Row_Name ,
                    a.Qty_Seat ,
                    a.Block_Purchase_Price ,
                    a.Paid_Amount ,
                    a.Owed_Amount 
            FROM    #tmpOutput a
            WHERE   a.Season_Name = p.Season_Name
            FOR     XML PATH('Child') ,
                        TYPE
			) AS 'Children'                
		FROM #tmpParent p
		ORDER BY p.Season_Year DESC
				, p.Order_Value DESC
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

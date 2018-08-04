SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [api].[CRM_Primary_Ticketing_Transactions_bkp]
    (
      @SSB_CRMSYSTEM_ACCT_ID VARCHAR(50) = 'test'
	, @SSB_CRMSYSTEM_CONTACT_ID VARCHAR(50) = 'test'
    , @RowsPerPage INT = 500
    , --APIification
      @PageNumber INT = 0 --APIification
    )
AS
    BEGIN

-- =========================================
-- Initial Variables for API
-- =========================================

        DECLARE @totalCount INT
          , @xmlDataNode XML
          , @recordsInResponse INT
          , @remainingCount INT
          , @rootNodeName NVARCHAR(100)
          , @responseInfoNode NVARCHAR(MAX)
          , @finalXml XML;

-- =========================================
-- GUID Table for GUIDS
-- =========================================
DECLARE @GUIDTable TABLE ( GUID VARCHAR(50) );

IF ( @SSB_CRMSYSTEM_ACCT_ID NOT IN ( 'None', 'Test' ) )
    BEGIN
        INSERT  INTO @GUIDTable
                ( GUID
                )
                SELECT DISTINCT
                        z.SSB_CRMSYSTEM_CONTACT_ID
                FROM    dbo.vwDimCustomer_ModAcctId z
                WHERE   z.SSB_CRMSYSTEM_ACCT_ID = @SSB_CRMSYSTEM_ACCT_ID;
    END;

IF ( @SSB_CRMSYSTEM_CONTACT_ID NOT IN ( 'None', 'Test' ) )
    BEGIN
        INSERT  INTO @GUIDTable
                ( GUID
                )
                SELECT  @SSB_CRMSYSTEM_CONTACT_ID;
    END;

-- =========================================
-- Base Table Set
-- =========================================


        DECLARE @baseData TABLE
            (
              Team NVARCHAR(255)
			, Account NVARCHAR(255)
            , SeasonName NVARCHAR(255)
            , OrderNumber NVARCHAR(255)
            , OrderLine NVARCHAR(255)
            , OrderDate DATE
            , Item NVARCHAR(255)
            , ItemName NVARCHAR(255)
			, EventDate NVARCHAR(255)
            , PriceCode NVARCHAR(255)
            , IsComp BIT
            , PromoCode NVARCHAR(255)
            , Qty INT
			, SectionName NVARCHAR(255)
            , RowName NVARCHAR(255)
			, SeatBlock	 NVARCHAR(255)
            , Total DECIMAL(18, 6)
			, SeatPrice DECIMAL(18, 6)
            , AmountOwed DECIMAL(18, 6)
            , AmountPaid DECIMAL(18, 6)
			, SalesRep NVARCHAR(255)
            );

-- =========================================
-- Procedure
-- =========================================


SELECT DISTINCT
        'Missouri' AS Team
      , fts.SSID_acct_id
      , ds.SeasonName
      , fts.OrderNum AS OrderNumber
      , fts.OrderLineItem AS OrderLine
      , dd.CalDate AS OrderDate
      , di.ItemCode AS Item
      , di.ItemName
	  , de.EventDate
      , dpc.PriceCode
      , fts.IsComp
      , dp2.PromoCode
      , fts.QtySeat AS Qty
      , ds2.SectionName
      , ds2.RowName
      , CONVERT(NVARCHAR, ds2.Seat) + ':' + CONVERT(NVARCHAR, ( ds2.Seat
                                                              + fts.QtySeat
                                                              - 1 )) SeatBlock
      , fts.PcPrice AS SeatPrice
      , fts.BlockPurchasePrice
      , fts.OwedAmount
      , fts.PaidAmount
	  , fts.SSCreatedBy AS SalesRep
INTO #Trans
FROM    dbo.FactTicketSales AS fts
        JOIN dbo.dimcustomerssbid AS d ON d.DimCustomerId = fts.DimCustomerId
        JOIN dbo.DimSeason AS ds ON ds.DimSeasonId = fts.DimSeasonId
        JOIN dbo.DimItem AS di ON di.DimItemId = fts.DimItemId
        JOIN dbo.DimPriceCode AS dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
        JOIN dbo.DimTicketClass AS dtc ON dtc.DimTicketClassId = fts.DimTicketTypeId
        JOIN dbo.DimTicketType AS dtt ON fts.DimTicketTypeId = fts.DimTicketTypeId
        JOIN dbo.DimPlan AS dp ON dp.DimPlanId = fts.DimPlanId
        JOIN dbo.DimDate AS dd ON dd.DimDateId = fts.DimDateId
		JOIN dbo.DimEvent AS de ON de.DimEventId = fts.DimEventId
        JOIN dbo.DimPromo AS dp2 ON dp2.DimPromoID = fts.DimPromoId
        JOIN dbo.DimSeat AS ds2 ON ds2.DimSeatId = fts.DimSeatIdStart
WHERE   d.SSB_CRMSYSTEM_CONTACT_ID IN (SELECT GUID FROM @GUIDTable);



-- =========================================
-- API Pagination
-- =========================================
-- Cap returned results at 1000

        IF @RowsPerPage > 1000
            BEGIN

                SET @RowsPerPage = 1000;

            END;

-- Pull total count

        SELECT  @totalCount = COUNT(*)
        FROM    #Trans AS c;

-- =========================================
-- API Loading
-- =========================================

-- Load base data

        INSERT  INTO @baseData
                SELECT  *
                FROM    #Trans AS c
                ORDER BY c.OrderDate DESC
                      , c.OrderNumber
                      OFFSET ( @PageNumber ) * @RowsPerPage ROWS

FETCH NEXT @RowsPerPage ROWS ONLY;

-- Set records in response

        SELECT  @recordsInResponse = COUNT(*)
        FROM    @baseData;
-- Create XML response data node

        SET @xmlDataNode = (
                             SELECT ISNULL(Team, '') AS Team
                                 
                                  , ISNULL(SeasonName,'') AS SeasonName
                                  , ISNULL(OrderNumber,'') AS OrderNumber
                                  , ISNULL(OrderLine,'') AS OrderLine
                                  , ISNULL(Account,'') AS Account
                                  , ISNULL(OrderDate,'') AS OrderDate
                                  , ISNULL(Item,'') AS Item
                                  , ISNULL(ItemName,'') AS ItemName
								  , ISNULL(EventDate,'') AS EventDate                                 
                                  , ISNULL(IsComp,0) AS IsComp                                
                                  , ISNULL(PromoCode,'') AS PromoCode
                                  , ISNULL(Qty,0) AS Qty
                                  , ISNULL(SeatPrice,0) AS SeatPrice
                                  , ISNULL(Total,0) AS Total
								  , ISNULL(SectionName,0) AS SectionName
								  , ISNULL(RowName,0) AS RowName
                                  , ISNULL(SeatBlock,'') AS SeatBlock
								  , ISNULL(SalesRep,'') AS SalesRep
                             FROM   @baseData
                           FOR
                             XML PATH('Parent')
                               , ROOT('Parents')
                           );

        SET @rootNodeName = 'Parents';

		-- Calculate remaining count

        SET @remainingCount = @totalCount - ( @RowsPerPage * ( @PageNumber + 1 ) );

        IF @remainingCount < 0
            BEGIN

                SET @remainingCount = 0;

            END;

			-- Create response info node

        SET @responseInfoNode = ( '<ResponseInfo>' + '<TotalCount>'
                                  + CAST(@totalCount AS NVARCHAR(20))
                                  + '</TotalCount>' + '<RemainingCount>'
                                  + CAST(@remainingCount AS NVARCHAR(20))
                                  + '</RemainingCount>'
                                  + '<RecordsInResponse>'
                                  + CAST(@recordsInResponse AS NVARCHAR(20))
                                  + '</RecordsInResponse>'
                                  + '<PagedResponse>true</PagedResponse>'
                                  + '<RowsPerPage>'
                                  + CAST(@RowsPerPage AS NVARCHAR(20))
                                  + '</RowsPerPage>' + '<PageNumber>'
                                  + CAST(@PageNumber AS NVARCHAR(20))
                                  + '</PageNumber>' + '<RootNodeName>'
                                  + @rootNodeName + '</RootNodeName>'
                                  + '</ResponseInfo>' );
    END;

-- Wrap response info and data, then return    

    IF @xmlDataNode IS NULL
        BEGIN

            SET @xmlDataNode = '<' + @rootNodeName + ' />';

        END;

    SET @finalXml = '<Root>' + @responseInfoNode
        + CAST(@xmlDataNode AS NVARCHAR(MAX)) + '</Root>';

    SELECT  CAST(@finalXml AS XML);










GO

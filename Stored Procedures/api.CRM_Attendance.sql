SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







--EXEC [api].[CRM_Attendance] @SSB_CRMSYSTEM_ACCT_ID = '528BDBC1-3591-446B-93F1-2F541C1DC801'
--EXEC [api].[CRM_Attendance] @SSB_CRMSYSTEM_CONTACT_ID = '774AB5F5-535F-4F3F-A04C-1109A28416A3'

CREATE PROCEDURE [api].[CRM_Attendance]
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


SELECT ssbid.SSB_CRMSYSTEM_CONTACT_ID
	  ,Season_Name
	  ,Event_Code
	  ,Event_Name
	  ,Event_Date
	  ,Event_Time
	  ,Section_Name
	  ,Row_Name
	  ,Seat
	  ,Scan_Time
	  ,Game_Scan_Time_Difference
	  ,Scan_Gate
	  ,IsAttended
INTO #tmpbase
FROM (  SELECT  COALESCE(fi.ResoldDimCustomerId,fi.SoldDimCustomerId) AS AttendedDimcustomerID
				, DimSeason.SeasonName AS Season_Name
				, DimEvent.EventCode AS Event_Code
				, DimEvent.EventName AS Event_Name
				, DimEvent.EventDate AS Event_Date
				, DimEvent.EventTime Event_Time
				, DimSeat.SectionName AS Section_Name
				, DimSeat.RowName AS Row_Name
				, DimSeat.Seat AS Seat
				, CAST(fi.ScanDateTime AS TIME) Scan_Time
				, DATEDIFF(MINUTE,dimevent.eventtime,CAST(fi.ScanDateTime AS TIME)) Game_Scan_Time_Difference
				, fi.ScanGate AS Scan_Gate
				, fi.IsAttended --hide from api view on front end		
		FROM      dbo.FactInventory fi
				INNER JOIN dbo.DimEvent DimEvent WITH ( NOLOCK ) ON DimEvent.DimEventId = fi.DimEventId
				INNER JOIN dbo.DimSeason DimSeason WITH ( NOLOCK ) ON DimSeason.DimSeasonId = DimEvent.DimSeasonId
				INNER JOIN dbo.DimSeat DimSeat WITH ( NOLOCK ) ON DimSeat.DimSeatId = fi.DimSeatId				
				INNER JOIN dbo.DimEventHeader DimEventHeader WITH ( NOLOCK ) ON DimEventHeader.DimEventHeaderId = DimEvent.DimEventHeaderId
				INNER JOIN dbo.DimSeasonHeader DimSeasonHeader WITH ( NOLOCK ) ON DimSeasonHeader.DimSeasonHeaderId = DimEventHeader.DimSeasonHeaderId
	    WHERE DimEvent.EventDate <= CAST(GETDATE()+1 AS DATE)
	  )x
	  INNER JOIN dbo.DimCustomer DimCustomer WITH ( NOLOCK ) ON DimCustomer.DimCustomerId = x.AttendedDimcustomerID
																   AND DimCustomer.CustomerType = 'Primary'
																   AND DimCustomer.SourceSystem = 'TM'
	  INNER JOIN dbo.dimcustomerssbid ssbid WITH ( NOLOCK ) ON ssbid.DimCustomerId = DimCustomer.DimCustomerId
WHERE ssbid.SSB_CRMSYSTEM_CONTACT_ID IN (SELECT GUID FROM @GUIDTable)

SELECT  ISNULL(Season_Name, '') Season_Name ,
        ISNULL(Event_Code, '') Event_Code ,
        ISNULL(Event_Name, '') Event_Name ,
        ISNULL(Event_Date, '') Event_Date ,
        ISNULL(CONVERT(VARCHAR(15), Event_Time, 0), '') Event_Time ,
        ISNULL(CONVERT(VARCHAR(15), Scan_Time, 0), '') Scan_Time ,
        ( CASE WHEN IsAttended = 1 THEN Game_Scan_Time_Difference
               ELSE NULL
          END ) True_GameScanDiff ,
        ISNULL(CAST(LTRIM(RTRIM(STR(ABS(CASE WHEN IsAttended = 1
                                             THEN Game_Scan_Time_Difference
                                             ELSE NULL
                                        END)))) + ' minute'
               + CASE WHEN Game_Scan_Time_Difference = 0 THEN ''
                      ELSE 's'
                 END + CASE WHEN Game_Scan_Time_Difference < 0 THEN ' early'
                            ELSE ' late'
                       END AS VARCHAR(50)), '') Game_Scan_Time_Difference ,
        ISNULL(Scan_Gate, '') Scan_Gate ,
        ISNULL(IsAttended, '') IsAttended ,
        ISNULL(Section_Name, '') Section_Name ,
        ISNULL(Row_Name, '') Row_Name ,
        ISNULL(Seat, '') Seat
INTO    #tmpOutput
FROM    #tmpbase
ORDER BY Event_Date ,
        Row_Name ASC ,
        Seat ASC
        OFFSET ( @PageNumber ) * @RowsPerPage ROWS
FETCH NEXT @RowsPerPage ROWS ONLY


SELECT CAST(Season_Name AS VARCHAR(50)) Season_Name
, COUNT(CASE WHEN Event_Date <= GETDATE() THEN Event_Code ELSE NULL END) Total_Available
, SUM(CAST(IsAttended AS INT)) Total_Attended
, ISNULL(
			CAST(CAST(
				(SUM(CAST(IsAttended AS INT)) / CAST(NULLIF(COUNT(CASE WHEN Event_Date <= GETDATE() THEN Event_Code ELSE NULL END),0) AS float))*100 
				AS DECIMAL(18,1)) 
			AS VARCHAR(50)) + '%','') [Percent_Attended]
, ISNULL(LTRIM(RTRIM(STR(ABS(AVG(CASE WHEN IsAttended = 1 THEN Game_Scan_Time_Difference ELSE NULL END))))) + ' minute' 
		+ CASE WHEN AVG(CASE WHEN IsAttended = 1 THEN Game_Scan_Time_Difference ELSE NULL END) = 0 THEN '' ELSE 's' END 
		+ CASE WHEN AVG(CASE WHEN IsAttended = 1 THEN Game_Scan_Time_Difference ELSE NULL END) < 0 THEN ' early' ELSE ' late' END,'') Avg_Scan_Time
INTO #tmpParent
FROM #tmpBase
GROUP BY CAST(Season_Name AS VARCHAR(50))
-- DROP TABLE #tmpParent

-- Pull counts
SELECT @recordsInResponse = COUNT(*) FROM #tmpOutput
SELECT @totalCount = COUNT(*) FROM #tmpBase

SET @xmlDataNode = (
		SELECT * ,
			(
            SELECT  a.Season_Name ,
                    a.Event_Code ,
                    a.Event_Name ,
                    a.Event_Date ,
                    a.Event_Time ,
                    a.Scan_Time ,
                    a.Game_Scan_Time_Difference ,
                    a.Scan_Gate ,
                    a.Section_Name ,
                    a.Row_Name ,
                    a.Seat 
            FROM    #tmpOutput a
            WHERE   a.Season_Name = p.Season_Name
            ORDER BY Event_Date 
            FOR     XML PATH('Child') ,
                        TYPE
			) AS 'Children'                
		FROM #tmpParent p
		ORDER BY p.Season_Name DESC
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

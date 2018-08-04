SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROC [rpt].[Football_HOB_3] (@SeasonYear INT)
AS

--DECLARE @SeasonYear INT = 2017
--EXEC rpt.Football_HOB_3 @SeasonYear

DECLARE @CurrentYear	INT = @SeasonYear

--=============================================================================================
--HEADER
--=============================================================================================

CREATE TABLE #Header (
EventDate Date
,EventCode VARCHAR(20)
,EventDisplay VARCHAR(100)
,BudgetQTY INT
,BudgetREV NUMERIC(18,2)
)

INSERT INTO #Header
(
    EventDate,
    EventCode,
	EventDisplay,
    BudgetQTY,
    BudgetREV
)

SELECT EventDate
	  ,x.EventCode
	  ,CONCAT(x.Opponent,' - ',EventDate) EventDisplay
	  ,x.BudgetQTY
	  ,x.BudgetRev
FROM (
		SELECT DimEvent.EventDate
			  ,DimEvent.EventCode
			  ,RIGHT(DimEvent.EventDesc, LEN(DimEvent.EventDesc) - CHARINDEX('vs.',DimEvent.EventDesc) - 3) Opponent
			  ,0 BudgetQTY
			  ,0 BudgetRev
		FROM dbo.DimEvent DimEvent (NOLOCK)
			JOIN dbo.DimSeason DimSeason (NOLOCK) ON DimSeason.DimSeasonId = DimEvent.DimSeasonId
		WHERE SeasonClass = 'Football'
			  AND seasonyear = @CurrentYear
			  AND DimEvent.EventName NOT LIKE '%chairbacks%'
	 )x
ORDER BY x.EventDate


--=============================================================================================
--SALES
--=============================================================================================

CREATE TABLE #Sales(
EventCode VARCHAR(30)
, EventDate DATE
, TicketType VARCHAR(100)
, QTY INT
, REV NUMERIC(18,2)
)

--=================================
--Football
--=================================

INSERT INTO #Sales

SELECT dimEvent.EventCode
	  ,dimEvent.EventDate
	  ,dimTicketType.TicketTypeName TicketType
	  ,SUM(fts.QtySeat) QTY
	  ,SUM(((dimPriceCode.Price - 8) / 1.07975 + 8)*fts.QtySeat) REV
FROM dbo.FactTicketSales fts (NOLOCK)
	JOIN dbo.DimSeason dimseason (NOLOCK) ON dimseason.DimSeasonId = fts.DimSeasonId
	JOIN dbo.DimEvent dimEvent (NOLOCK) ON dimEvent.DimEventId = fts.DimEventId
	JOIN dbo.DimPriceCode dimPriceCode (NOLOCK) ON dimPriceCode.DimPriceCodeId = fts.DimPriceCodeId
	JOIN dbo.DimTicketType dimTicketType (NOLOCK) ON dimTicketType.DimTicketTypeId = fts.DimTicketTypeId
WHERE 1=1
	  AND (dimTicketType.TicketTypeName IN ('Single Game','Group') OR TicketTypeName IS NULL)
	  AND SeasonClass IN ('Football')
	  AND seasonyear = @SeasonYear
GROUP BY dimEvent.EventCode
	  ,dimEvent.EventDate
	  ,dimTicketType.TicketTypeName

--=============================================================================================
--OUTPUT
--=============================================================================================

SELECT CASE GROUPING_ID(headers.EventDate ,headers.EventDisplay)
			WHEN 0 THEN 'Event Summary'
			ELSE 'Grand Total'
	   END	AS RowType
	  ,headers.EventDate																			AS EventDate
	  ,headers.EventDisplay																			AS EventDisplay
	  ,SUM(headers.BudgetQTY)																		AS BudgetQTY
	  ,SUM(headers.BudgetREV)																		AS BudgetREV
	  ,SUM(ISNULL(VisitingQTY	,0))																AS VisitingQTY
	  ,SUM(ISNULL(VisitingREV	,0))																AS VisitingREV
	  ,SUM(ISNULL(StudentQTY	,0))																AS StudentQTY
	  ,SUM(ISNULL(StudentREV	,0))																AS StudentREV
	  ,SUM(ISNULL(GroupQTY		,0))																AS GroupQTY
	  ,SUM(ISNULL(GroupREV		,0))																AS GroupREV
	  ,SUM(ISNULL(PublicQTY		,0))																AS PublicQTY
	  ,SUM(ISNULL(PublicREV		,0))																AS PublicREV
	  ,SUM(ISNULL(TotalQTY		,0))																AS TotalQTY
	  ,SUM(ISNULL(TotalREV		,0))																AS TotalREV
	  ,CAST(ISNULL(1.0*SUM(Sales.TotalREV)/NULLIF(SUM(headers.BudgetREV),0),0) AS DECIMAL (8,6))	AS PctToGoal
	  ,SUM(ISNULL(Sales.TotalREV,0)) - SUM(ISNULL(BudgetREV,0)) 									AS VarianceFromGoal
INTO #Results
FROM #Header headers
	LEFT JOIN (SELECT EventCode
					 ,SUM(CASE WHEN TicketType = 'Visiting' THEN QTY END)	AS VisitingQTY
					 ,SUM(CASE WHEN TicketType = 'Visiting' THEN REV END)	AS VisitingREV
					 ,SUM(CASE WHEN TicketType = 'Student' THEN QTY END)	AS StudentQTY
					 ,SUM(CASE WHEN TicketType = 'Student' THEN REV END)	AS StudentREV
					 ,SUM(CASE WHEN TicketType = 'Group' THEN QTY END)		AS GroupQTY
					 ,SUM(CASE WHEN TicketType = 'Group' THEN REV END)		AS GroupREV
					 ,SUM(CASE WHEN TicketType = 'Public' THEN QTY END)		AS PublicQTY
					 ,SUM(CASE WHEN TicketType = 'Public' THEN REV END)		AS PublicREV
					 ,SUM(QTY)												AS TotalQTY
					 ,SUM(REV)												AS TotalREV
			   FROM #Sales
			   GROUP BY EventCode
			   )sales ON sales.EventCode = headers.EventCode
GROUP BY GROUPING SETS (
						 (headers.EventDate ,headers.EventDisplay)
						,()
						)
ORDER BY EventDate

--=============================================================================================
--YTD
--=============================================================================================

SELECT results.*
	  ,ytd.VarianceFromGoal_YTD
	  ,ytd.BudgetREV_YTD	
	  ,ytd.TotalREV_YTD
	  ,ytd.PctToGoal_YTD
FROM #Results results
	LEFT JOIN (SELECT results.EventDate
					 ,SUM(ISNULL(YTD.TotalRev,0)) - SUM(ISNULL(YTD.BudgetREV,0))							AS VarianceFromGoal_YTD
					 ,SUM(ISNULL(YTD.BudgetREV,0))															AS BudgetREV_YTD	
					 ,SUM(ISNULL(YTD.TotalRev,0))															AS TotalREV_YTD
					 ,CAST(ISNULL(1.0*SUM(YTD.TotalRev)/NULLIF(SUM(YTD.BudgetREV),0),0) AS DECIMAL (8,6))	AS PctToGoal_YTD
			   FROM #Results results
				JOIN #Results YTD ON YTD.EventDate <= results.EventDate
			   WHERE results.RowType = 'Event Summary'
					 AND YTD.RowType = 'Event Summary'
			   GROUP BY results.EventDate
			   )YTD ON YTD.EventDate = results.EventDate
ORDER BY RowType, EventDate


--DROP TABLE #Header
--DROP TABLE #Results
--DROP TABLE #Sales



	  
	  
	  
	  
GO

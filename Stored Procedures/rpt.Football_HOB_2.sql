SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROC [rpt].[Football_HOB_2] (@SeasonYear INT,@YTD BIT)
AS

--DECLARE @SeasonYear INT = 2018
--DECLARE @YTD BIT = 1

--EXEC rpt.Football_HOB_2_DEV @SeasonYear, 0
--EXEC rpt.Football_HOB_2_DEV @SeasonYear, 1

DECLARE @CurrentYear INT					= @SeasonYear
DECLARE @PriorYear	 INT					= @SeasonYear - 1

DECLARE @DateFilter_PY DATE = CASE WHEN @YTD = 1 THEN DATEADD(YEAR	,-1,GETDATE()) ELSE GETDATE() END 

--=============================================================================================
--HEADER
--=============================================================================================

CREATE TABLE #Header (
SortOrder INT 
,PricePoint VARCHAR(100)
,Capacity INT
,DimSeatTypeID INT
)

INSERT INTO #Header

SELECT CASE DimSeatTypeId WHEN 1	THEN 1
						  WHEN 3	THEN 2
						  WHEN 4	THEN 3
						  WHEN 5	THEN 4
						  WHEN 7	THEN 5
						  WHEN 8	THEN 6
						  WHEN 9	THEN 6
						  WHEN 10	THEN 7
						  WHEN 11	THEN 7
		END SortOrder
	  ,CASE DimSeatTypeId WHEN 1	THEN 'Sidelines' 
						  WHEN 3	THEN 'Tiger Deck - Rows 1-4'
						  WHEN 4	THEN 'Tiger Deck - Rows 5-16'
						  WHEN 5	THEN 'Rock M GA Hill'
						  WHEN 7	THEN 'Tiger Lounge'
						  WHEN 8	THEN 'Suites'						
						  WHEN 9	THEN 'Suites'						
						  WHEN 10	THEN 'Columns Club'					
						  WHEN 11	THEN 'Columns Club'					
	   END PricePoint
	  ,0 Capacity
	  ,DimSeatTypeId
FROM dbo.DimSeatType
WHERE DimSeatTypeId IN (
 1	--LL - Sideline
,3	--Tiger Deck 1-4
,4	--TIger Deck 5-16
,5	--Rock M Hill
,7	--Tiger Lounge
,8	--Suites
,9	-- West Club
,10	-- East Club
,11	-- East Loge
)

--=============================================================================================
--SALES
--=============================================================================================


SELECT x.DimSeatTypeId
	  ,x.SeasonYear
	  ,SUM(CASE WHEN x.IsRenewal = 1 THEN x.QtySeat END)					AS QTY_RENEW
	  ,SUM(CASE WHEN x.IsRenewal = 0 THEN x.QtySeat END)					AS QTY_NEW
	  ,SUM(x.QtySeat)														AS QTY
	  ,SUM(CASE WHEN x.IsRenewal = 1 THEN x.QtySeat*x.AdjustedPrice END)	AS REV_RENEW
	  ,SUM(CASE WHEN x.IsRenewal = 0 THEN x.QtySeat*x.AdjustedPrice END)	AS REV_NEW
	  ,SUM(x.QtySeat*x.AdjustedPrice)										AS REV
INTO #Sales
FROM (
		SELECT dimSeattype.DimSeatTypeId
			  ,dimSeason.SeasonYear
			  ,CASE WHEN dimPlantype.PlanTypeCode = 'RENEW' THEN 1 ELSE 0 END AS IsRenewal
			  ,CASE WHEN fts.DimEventId > 0 AND dimtickettype.TicketTypeName IN ('Faculty/Staff','Full Season','Young Alum') THEN fts.QtySeatFSE ELSE fts.QtySeat END QtySeat
			  ,(dimPriceCode.Price - 56) / 1.07975 + 56 AdjustedPrice		--accounts for tax REV
		FROM dbo.FactTicketSales fts (NOLOCK)	
			JOIN dbo.DimTicketType dimtickettype (NOLOCK) ON dimtickettype.DimTicketTypeId = fts.DimTicketTypeId
			JOIN dbo.DimSeatType dimSeattype (NOLOCK) ON dimSeattype.DimSeatTypeId = fts.DimSeatTypeId
			JOIN dbo.DimPlanType dimPlantype (NOLOCK) ON dimPlantype.DimPlanTypeId = fts.DimPlanTypeId
			JOIN dbo.DimSeason dimSeason (NOLOCK) ON dimSeason.DimSeasonId = fts.DimSeasonId
			JOIN dbo.DimDate dimDate (NOLOCK) ON dimDate.DimDateId = fts.DimDateId
			JOIN dbo.DimPriceCode dimPriceCode (NOLOCK) ON dimPriceCode.DimPriceCodeId = fts.DimPriceCodeId
		WHERE dimSeason.SeasonClass IN ('Football')
			  AND (dimSeason.SeasonYear = @CurrentYear 
				   OR (SeasonYear = @PriorYear AND CalDate < @DateFilter_PY)
				   )
			  AND dimtickettype.TicketTypeName IN ('Young Alum','Faculty/Staff','Full Season')
	  )x
GROUP BY x.DimSeatTypeId
	  ,x.SeasonYear

--=============================================================================================
--OUTPUT
--=============================================================================================

SELECT CASE GROUPING_ID(header.SortOrder,header.PricePoint,header.Capacity) 
			WHEN 0 THEN 'Detail'
			ELSE 'Total'
	   END RowType
	  ,header.SortOrder
	  ,header.PricePoint
	  ,header.Capacity
	  ,SUM(ISNULL(py.QTY,0)) QTY_PY
	  ,SUM(ISNULL(cy.QTY_Renew,0)) QTY_CY_Renew
	  ,CAST(ISNULL(1.0*SUM(cy.QTY_Renew)/NULLIF(SUM(py.QTY),0),0) AS DECIMAL(18,6)) QTY_PercentRenew
	  ,SUM(ISNULL(cy.QTY_NEW,0)) QTY_CY_New
	  ,SUM(ISNULL(cy.QTY,0)) QTY_CY_Total
	  ,SUM(ISNULL(cy.REV_Renew,0)) REV_CY_Renew
	  ,SUM(ISNULL(cy.REV_NEW,0)) REV_CY_New
	  ,SUM(ISNULL(cy.REV,0)) REV_CY_Total
FROM #Header header
	LEFT JOIN #Sales cy ON cy.DimSeatTypeId = header.DimSeatTypeID
							AND cy.SeasonYear = @CurrentYear
	LEFT JOIN #Sales py ON py.DimSeatTypeId = header.DimSeatTypeID
							AND py.SeasonYear = @PriorYear
GROUP BY GROUPING SETS(
						(header.SortOrder,header.PricePoint,header.Capacity)
						,()
						)
ORDER BY RowType, header.SortOrder



DROP TABLE #Header
DROP TABLE #Sales
GO

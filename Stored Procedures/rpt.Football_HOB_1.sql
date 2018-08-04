SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- Author name: Jeff Barberio

-- Created date: ? Precedes Template Creation

-- Purpose: Manual Dimcustomer Load view for adhoc loads

-- Copyright © 2018, SSB, All Rights Reserved

-------------------------------------------------------------------------------

-- Modification History --

-- 6/11/2018: Jeff Barberio

	-- Change notes: Added in value for Budget_Rev
	
	-- Peer reviewed by: Jeff Barberio
	
	-- Peer review notes: 
	
	-- Peer review date: 6/14/2018
	
	-- Deployed by:
	
	-- Deployment date:
	
	-- Deployment notes:

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------



CREATE PROC [rpt].[Football_HOB_1] (@SeasonYear INT, @YTD BIT)
AS

--DECLARE @SeasonYear INT = 2018
--DECLARE @YTD BIT = 1

--EXEC rpt.Football_HOB_1_DEV @SeasonYear, 0
--EXEC rpt.Football_HOB_1_DEV @SeasonYear, 1

DECLARE @CurrentYear INT					= @SeasonYear
DECLARE @PriorYear	 INT					= @SeasonYear - 1

DECLARE @DateFilter_PY DATE = CASE WHEN @YTD = 1 THEN DATEADD(YEAR	,-1,GETDATE()) ELSE GETDATE() END 

DECLARE @SeasonDonationFund_CY VARCHAR(20)  = CONCAT(RIGHT(@CurrentYear,2),'TSF')
DECLARE @SeasonDonationFund_PY VARCHAR(20)  = CONCAT(RIGHT(@PriorYear,2),'TSF')

--=============================================================================================
--HEADER
--=============================================================================================

CREATE TABLE #Header (
SortOrder INT IDENTITY(1,1)
,Section VARCHAR(30)
,Category VARCHAR(100)
,RevenueCategory VARCHAR(100)
,Goal_Rev NUMERIC(18,2)
,Budget_Rev NUMERIC(18,2)
)

INSERT INTO #Header
(
    Section,
    Category,
    RevenueCategory,
	Goal_Rev,
	Budget_Rev
)
VALUES


 ('Top'		, 'Student Season Combo'	,'Student Season Combo'							,0			,0)
,('Top'		, 'Student Football Only'	,'Student Football Only'						,0			,0)
,('Top'		, 'Single Premium'			,'Single Premium'								,0			,0)
,('Top'		, 'Season Premium'			,'Season Premium'								,0			,0)
,('Top'		, 'Single Game Tickets'		,'Single Game Tickets'							,0			,0)
,('Top'		, 'Mini Plans'				,'Mini Plans'									,0			,0)
,('Top'		, 'Season Tickets'			,'Season Tickets'								,11000000	,10125000) --20180614 jbarberio added in "Budget_Rev" Value
,('Bottom'	, 'Donor Seats'				,'Seat Related Contributions (Season Tickets)'	,0			,0)
,('Bottom'	, 'Season Ticket Accounts'	,NULL											,0			,0)


--=============================================================================================
--SALES
--=============================================================================================

CREATE TABLE #Sales (
Category VARCHAR(100)
,SeasonYear INT
,QTY INT
,REV NUMERIC(18,2)
)


--===========================================
--Tickets
--===========================================

INSERT INTO #Sales

SELECT Category
	  ,SeasonYear
	  ,SUM(x.QtySeat) QTY
	  ,SUM(CASE WHEN x.Category = 'Student Season Combo' THEN .5 ELSE 1 END*x.QtySeat*x.AdjustedPrice) REV --half the revenue for combo item between FB/MB
FROM (
		SELECT CASE WHEN dimPriceCode.PriceCode = 'STC' THEN 'Student Season Combo'
					WHEN dimPriceCode.PriceCode = 'FO' THEN 'Student Football Only'
					WHEN SeatTypeName IN ('Tiger Lounge','Suites','West Club','East Club','East Loge') THEN CASE WHEN dimPlantype.PlanTypeCode = 'NO PLAN' THEN 'Single Premium'			
																												  ELSE 'Season Premium'			
																											 END
					WHEN dimtickettype.TicketTypeName IN ('Group','Single Game') THEN 'Single Game Tickets'		
					WHEN dimtickettype.TicketTypeName = 'Partial Plan' THEN 'Mini Plans'				
					WHEN dimtickettype.TicketTypeName IN ('Faculty/Staff','Full Season','Young Alum') THEN 'Season Tickets'			
			   END AS Category
			   ,dimSeason.SeasonYear
			   ,CASE WHEN fts.DimEventId > 0 AND dimtickettype.TicketTypeName IN ('Faculty/Staff','Full Season','Young Alum') THEN fts.QtySeatFSE ELSE fts.QtySeat END QtySeat
			   ,CASE WHEN dimPriceCode.Price = 0 THEN 0
					 WHEN dimtickettype.TicketTypeClass = 'Season' THEN (dimPriceCode.Price - 56) / 1.07975 + 56
					 ELSE (dimPriceCode.Price - 8) / 1.07975 + 8
				END AdjustedPrice--accounts for tax REV
			   ,COUNT(fts.DimEventId) OVER(PARTITION BY fts.OrderNum, fts.OrderLineItem, fts.OrderLineItemSeq) AS EventsInOrder
		FROM dbo.FactTicketSales fts (NOLOCK)	
			JOIN dbo.DimTicketType dimtickettype (NOLOCK) ON dimtickettype.DimTicketTypeId = fts.DimTicketTypeId
			JOIN dbo.DimSeatType dimSeattype (NOLOCK) ON dimSeattype.DimSeatTypeId = fts.DimSeatTypeId
			JOIN dbo.DimPlanType dimPlantype (NOLOCK) ON dimPlantype.DimPlanTypeId = fts.DimPlanTypeId
			JOIN dbo.DimSeason dimSeason (NOLOCK) ON dimSeason.DimSeasonId = fts.DimSeasonId
			JOIN dbo.DimDate dimDate (NOLOCK) ON dimDate.DimDateId = fts.DimDateId
			JOIN dbo.DimPriceCode dimPriceCode (NOLOCK) ON dimPriceCode.DimPriceCodeId = fts.DimPriceCodeId
		WHERE dimSeason.SeasonClass IN ('Football','Student')
			  AND (dimSeason.SeasonYear = @CurrentYear 
				   OR (SeasonYear = @PriorYear AND CalDate < @DateFilter_PY)
				   )
	  )x
GROUP BY Category
	  ,SeasonYear

--===========================================
--ST Accounts
--===========================================

INSERT INTO #Sales

SELECT 'Season Ticket Accounts' Category
	  ,dimSeason.SeasonYear
	  ,COUNT(DISTINCT fts.SSID_acct_id) QTY
	  ,NULL REV
FROM dbo.FactTicketSales fts (NOLOCK)
	JOIN dbo.DimTicketType dimtickettype  (NOLOCK) ON dimtickettype.DimTicketTypeId = fts.DimTicketTypeId
	JOIN dbo.DimSeatType dimSeattype  (NOLOCK) ON dimSeattype.DimSeatTypeId = fts.DimSeatTypeId
	JOIN dbo.DimPlanType dimPlantype  (NOLOCK) ON dimPlantype.DimPlanTypeId = fts.DimPlanTypeId
	JOIN dbo.DimSeason dimSeason  (NOLOCK) ON dimSeason.DimSeasonId = fts.DimSeasonId
	JOIN dbo.DimDate dimDate  (NOLOCK) ON dimDate.DimDateId = fts.DimDateId
	JOIN dbo.DimPriceCode dimPriceCode  (NOLOCK) ON dimPriceCode.DimPriceCodeId = fts.DimPriceCodeId
WHERE dimSeason.SeasonClass IN ('Football','Student')
			  AND (dimSeason.SeasonYear = @CurrentYear 
				   OR (SeasonYear = @PriorYear AND CalDate <= @DateFilter_PY)
				   )
	  AND dimtickettype.TicketTypeName IN ('Faculty/Staff','Full Season','Young Alum')
GROUP BY dimSeason.SeasonYear

--===========================================
--Donations
--===========================================

INSERT INTO #Sales (Category, SeasonYear, REV)

SELECT 'Donor Seats' Category
	  ,drive_year SeasonYear
	  ,SUM(pledge_amount) REV
FROM ods.TM_Donation
WHERE fund_name = @SeasonDonationFund_CY	
	  OR (fund_name = @SeasonDonationFund_PY AND add_datetime <= @DateFilter_PY)
GROUP BY drive_year

--=============================================================================================
--OUTPUT
--=============================================================================================

SELECT RowType
	  ,Section
	  ,SortOrder
	  ,Category
	  ,QTY_PY
	  ,QTY_CY
	  ,QTY_Variance_PY
	  ,RevenueCategory
	  ,REV_CY
	  ,CASE WHEN RowType = 'SectionTotal' AND Section = 'Top' THEN REV_Goal ELSE NULL END				REV_Goal
	  ,CASE WHEN RowType = 'SectionTotal' AND Section = 'Top' THEN REV_Variance_Goal ELSE NULL END		REV_Variance_Goal
	  ,CASE WHEN RowType = 'SectionTotal' AND Section = 'Top' THEN REV_PercentTo_Goal ELSE NULL END		REV_PercentTo_Goal
	  ,CASE WHEN RowType = 'SectionTotal' AND Section = 'Top' THEN REV_Budget ELSE NULL END				REV_Budget
	  ,CASE WHEN RowType = 'SectionTotal' AND Section = 'Top' THEN REV_PercentTo_Budget ELSE NULL END	REV_PercentTo_Budget
	  ,REV_PY
	  ,REV_Variance_PY
FROM (
		SELECT	CASE GROUPING_ID(header.Section,header.SortOrder,header.Category,header.RevenueCategory)
					 WHEN 0 THEN 'Detail'
					 ELSE 'SectionTotal'
				END																					AS RowType
			   ,header.Section																		AS Section
			   ,header.SortOrder																	AS SortOrder
			   ,header.Category																		AS Category
			   ,SUM(ISNULL(PY.QTY,0))																AS QTY_PY
			   ,SUM(ISNULL(CY.QTY,0))																AS QTY_CY
			   ,SUM(ISNULL(CY.QTY,0) - ISNULL(PY.QTY,0))											AS QTY_Variance_PY
			   ,header.RevenueCategory																AS RevenueCategory
			   ,SUM(ISNULL(CY.REV,0))																AS REV_CY
			   ,SUM(header.Goal_Rev)																AS REV_Goal
			   ,SUM(ISNULL(CY.REV,0) - header.Goal_Rev)												AS REV_Variance_Goal
			   ,CAST(ISNULL(1.0*SUM(CY.REV)/NULLIF(SUM(header.Goal_Rev),0),0) AS DECIMAL(18,4))		AS REV_PercentTo_Goal
			   ,SUM(header.Budget_Rev)																AS REV_Budget
			   ,CAST(ISNULL(1.0*SUM(CY.REV)/NULLIF(SUM(header.Budget_Rev),0),0) AS DECIMAL(18,4))	AS REV_PercentTo_Budget
			   ,SUM(ISNULL(PY.REV,0))																AS REV_PY
			   ,SUM(ISNULL(CY.REV,0)) - SUM(ISNULL(PY.REV,0))										AS REV_Variance_PY
		FROM #Header header
			LEFT JOIN #Sales CY ON CY.Category = header.Category AND CY.SeasonYear = @CurrentYear
			LEFT JOIN #Sales PY ON PY.Category = header.Category AND PY.SeasonYear = @PriorYear
		GROUP BY GROUPING SETS(
								(header.Section,header.SortOrder,header.Category,header.RevenueCategory)
							   ,(header.Section)
							   )
	 )x
ORDER BY Section DESC, RowType, SortOrder



DROP TABLE #Header
DROP TABLE #Sales



GO

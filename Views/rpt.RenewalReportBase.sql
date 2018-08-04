SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [rpt].[RenewalReportBase]

AS

--===================================
--Gather all season purchases for all 
--sports/years by dimcustomer and seat
--===================================

WITH CTE_baseRaw
AS ( SELECT  dimseason.SeasonClass Sport
	 		,dimseason.SeasonYear
	 		,fi.SoldDimCustomerId				
	 		,fi.DimSeatId
	 		,SUM(dimPriceCode.Price) AS TotalSeatRevenue
	 FROM dbo.FactInventory fi (NOLOCK)
	 	JOIN dbo.DimSeason dimseason (NOLOCK) ON dimseason.DimSeasonId = fi.DimSeasonId
	 	JOIN dbo.DimPriceCode dimPriceCode (NOLOCK) ON dimPriceCode.DimPriceCodeId = fi.SoldDimPriceCodeId
	 	JOIN dbo.FactTicketSales fts (NOLOCK) ON fts.FactTicketSalesId = fi.FactTicketSalesId
	 	JOIN dbo.DimTicketType dimTicketType (NOLOCK) ON dimTicketType.DimTicketTypeId = fts.DimTicketTypeId
	 WHERE fi.IsSold = 1
	 		AND dimTicketType.TicketTypeClass = 'season'
	 		AND tickettypeName <> 'Student'
	 		AND fi.TotalRevenue > 0
	 GROUP BY dimseason.SeasonClass
	 				,dimseason.SeasonYear
	 				,fi.SoldDimCustomerId				
	 				,fi.DimSeatId
	)

--===================================
-- Remove Dupes
--===================================

,CTE_Base
AS (SELECT base.*
	FROM CTE_baseRaw base
		LEFT JOIN (SELECT Sport ,SeasonYear ,DimSeatId
				   FROM CTE_baseRaw
				   GROUP BY Sport ,SeasonYear ,DimSeatId
				   HAVING COUNT(*) > 1
				   )dupes ON dupes.Sport = base.Sport
		 		  			AND dupes.SeasonYear = base.SeasonYear
		 		  			AND dupes.DimSeatId = base.DimSeatId
	WHERE dupes.dimseatid IS NULL
	)

--===================================================
--determine the quantity of renewed seats per person. 
--This will be used later to determine the quantity of 
--relocated seats that don't have exact matches
--===================================================

,CTE_renewalQTY
AS ( SELECT base.Sport
		  ,base.SeasonYear	
		  ,base.SoldDimCustomerId	
	 	  ,CASE WHEN base.TotalSeats < renewal.TotalSeats THEN base.totalSeats ELSE renewal.TotalSeats END AS NumRenewed
	 FROM (SELECT Sport
	 			,SeasonYear
	 			,SoldDimCustomerId
	 			,COUNT(base.DimSeatId) TotalSeats
	 	  FROM CTE_base base
	 	  GROUP BY Sport
	 			  ,SeasonYear
	 			  ,SoldDimCustomerId
	 	 )base
	 	LEFT JOIN (SELECT Sport
	 					 ,SeasonYear
	 					 ,SoldDimCustomerId
	 					 ,COUNT(base.DimSeatId) TotalSeats
	 			   FROM CTE_base base
	 			   GROUP BY Sport
	 					   ,SeasonYear
	 					   ,SoldDimCustomerId
	 			  )renewal ON renewal.Sport = base.Sport
	 						  AND renewal.SeasonYear = base.SeasonYear + 1
	 						  AND renewal.SoldDimCustomerId = base.SoldDimCustomerId
	)

--===================================================
--capture only the seats that are renewed for a given 
--sport/year utilizing the CTE_renewalQTY table for cases 
--without an exact match
--===================================================
,CTE_RenewedSeats
AS ( SELECT x.Sport
	 	  ,x.SeasonYear
	 	  ,x.SoldDimCustomerId
	 	  ,x.TotalSeatRevenue
	 	  ,x.DimSeatId
	 	  ,x.Relocated
	 	  ,1 AS Renewed
	 FROM (SELECT base.Sport
	 	  	    ,base.SeasonYear
	 	  	    ,base.SoldDimCustomerId
	 	  	    ,base.TotalSeatRevenue
	 	  	    ,base.DimSeatId
	 	  	    ,CASE WHEN renewal.DimSeatId IS NULL THEN 1 ELSE 0 END AS Relocated
	 	  	    ,RANK() OVER(PARTITION BY base.Sport
	 	  							     ,base.SeasonYear
	 	  							     ,base.SoldDimCustomerId 
	 	  				     ORDER BY CASE WHEN renewal.DimSeatId IS NULL THEN 1 ELSE 0 END
	 	  						     ,base.TotalSeatRevenue DESC
	 	  						     ,base.DimSeatId
	 	  				   ) rnk
	 	  FROM CTE_base base
	 	  	LEFT JOIN CTE_base renewal ON renewal.Sport = base.Sport
	 	  								AND renewal.SeasonYear = base.SeasonYear + 1
	 	  								AND renewal.SoldDimCustomerId = base.SoldDimCustomerId
	 	  								AND renewal.DimSeatId = base.DimSeatId
	 	  )x 
	 	  JOIN CTE_renewalQTY qty ON qty.SeasonYear = x.SeasonYear
	 								AND qty.Sport = x.Sport
	 								AND qty.SoldDimCustomerId = x.SoldDimCustomerId
	 								AND x.rnk <= qty.NumRenewed
	)
--===================================================
--Join the renewed seats back to the base table to create 
--the full set of renewed/non-renewed for reporting
--===================================================
,CTE_output
AS ( SELECT base.Sport
	 	  ,base.SeasonYear
	 	  ,base.SoldDimCustomerId
	 	  ,base.TotalSeatRevenue
	 	  ,base.DimSeatId
	 	  ,ISNULL(Relocated,0)	Relocated
	 	  ,ISNULL(Renewed,0)	Renewed

	 FROM CTE_base base
	 	LEFT JOIN CTE_RenewedSeats renewed ON renewed.Sport = base.Sport
	 										AND renewed.SeasonYear = base.SeasonYear
	 										AND renewed.SoldDimCustomerId = base.SoldDimCustomerId
	 										AND renewed.DimSeatId = base.DimSeatId
	)


SELECT sport, SeasonYear, SUM(TotalSeatRevenue) REV, COUNT(*) NumSeats
FROM CTE_output
WHERE Renewed = 1
GROUP BY sport, SeasonYear















GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO













CREATE PROCEDURE [etl].[Cust_FactTicketSalesProcessing_DEV]
(
	@BatchId INT = 0,
	@LoadDate DATETIME = NULL,
	@Options NVARCHAR(MAX) = NULL
)
AS

BEGIN

/*===============================================================================================
											CTE DECLARATION
===============================================================================================*/
--football are the only seasons that have been fleshed out so far for ticket types, more sports will need
--added as the rules are passed along

select CASE WHEN EventName LIKE '%chairbacks' THEN 'Football Chairbacks'
			WHEN seasonname = concat(seasonyear,' Mizzou Football') THEN 'Football'
			WHEN SeasonName = concat(seasonyear-1,'-',RIGHT(seasonyear,2),' Mizzou Men''s Basketball') THEN 'Mens Basketball'
	   END AS EventType
	   , de.DimEventId
INTO #Events
FROM dimseason ds
	JOIN dbo.DimEvent de ON de.DimSeasonId = ds.DimSeasonId
where seasonname = concat(seasonyear,' Mizzou Football') --football
	  OR ds.SeasonName = concat(seasonyear-1,'-',RIGHT(seasonyear,2),' Mizzou Men''s Basketball') --Mens Basketball
ORDER BY ds.SeasonName

select dimseasonid, seasonname
INTO #StudentSeasons 
FROM dimseason
where seasonname = concat(seasonyear,' Student Tickets')

/*===============================================================================================
											TICKET TYPE
===============================================================================================*/

--Full event
UPDATE fts
SET fts.DimTicketTypeId = 5
FROM #stgfactticketsales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE (event.EventType = 'Football' AND RIGHT(PriceCode,LEN(PriceCode)-1) IN ('BR','C','CM','D','FC','FN','FR'
																			 ,'G','M','N','PR','R','VM','X'))
	  OR event.EventType = 'Mens Basketball' AND RIGHT(dpc.PriceCode, LEN(dpc.PriceCode) - 1) IN ('BC','C','D','FH','FP','L','LA','LC','M','N','R','SR')

--Partial Plan
UPDATE fts
SET fts.DimTicketTypeId = 6
FROM #stgfactticketsales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE (event.EventType = 'Football' AND RIGHT(PriceCode,LEN(PriceCode)-1) IN ('MIZ','TIG','ZOU'))
	  OR (event.EventType = 'Mens Basketball' AND RIGHT(dpc.PriceCode, LEN(dpc.PriceCode) - 1) IN ('4','F','SEC'))


--Faculty/Staff
UPDATE fts
SET fts.DimTicketTypeId = 7
FROM #stgfactticketsales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE (event.EventType = 'Football' AND RIGHT(PriceCode,LEN(PriceCode)-1) IN ('FS','FN'))
	  OR (event.EventType = 'Mens Basketball' AND RIGHT(dpc.PriceCode, LEN(dpc.PriceCode) - 1) IN ('FN','FS','LH'))

--Single
UPDATE fts
SET fts.DimTicketTypeId = 8
FROM #stgfactticketsales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE (event.EventType = 'Football' AND RIGHT(PriceCode,LEN(PriceCode)-1) IN ('15','CS','G25','M','P','P2','S','T','H',''))
	  OR (event.EventType = 'Mens Basketball' AND RIGHT(dpc.PriceCode, LEN(dpc.PriceCode) - 1) IN ('','5','BY','P','RR','S','SC','SF','SG','SS','SW','V','W'))


--Student
UPDATE fts
SET fts.DimTicketTypeId = 9
FROM #stgfactticketsales fts	
	LEFT JOIN #StudentSeasons ss ON ss.dimseasonid = fts.DimSeasonId
	LEFT JOIN #events event ON event.DimeventId = fts.DimeventId
WHERE ss.DimSeasonId IS NOT NULL
	  OR (event.EventType = 'Mens Basketball' AND RIGHT(dpc.PriceCode, LEN(dpc.PriceCode) - 1) IN ('SI'	,'SO'))


--Young Alum
UPDATE fts
SET fts.DimTicketTypeId = 10
FROM #stgfactticketsales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE event.EventType = 'Football' AND RIGHT(PriceCode,LEN(PriceCode)-1) IN ('Y2','Y3','YA')


--Chair Backs
UPDATE fts
SET fts.DimTicketTypeId = 11
FROM #stgfactticketsales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE event.EventType = 'Football Chairbacks'

--Group
UPDATE fts
SET fts.DimTicketTypeId = 12
FROM #stgfactticketsales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE (event.EventType = 'Mens Basketball' AND RIGHT(PriceCode,LEN(PriceCode)-1) = 'G')

--Inventory
UPDATE fts
SET fts.DimTicketTypeId = 13
FROM #stgfactticketsales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE (event.EventType = 'Football' AND RIGHT(PriceCode,LEN(PriceCode)-1) = 'IN')
	  OR (event.EventType = 'Mens Basketball' AND RIGHT(PriceCode,LEN(PriceCode)-1) = 'IN')

/*===============================================================================================
											PLAN TYPE
===============================================================================================*/
/*
DimPlanTypeId	PlanTypeCode
1	NEW
2	RENEW
3	ADD
4	NO PLAN
*/
	
--Football
UPDATE fts
SET fts.DimPlanTypeId =	   CASE WHEN event.EventType = 'Football' THEN CASE WHEN pc2 = 'N' THEN 1
																			WHEN PriceCode = 'EM' THEN 1
																			WHEN pc2 = 'R' THEN 2
																			WHEN PriceCode = 'LBR' THEN 2
																			WHEN PriceCode = 'AVM' THEN 2
																			WHEN pc2 = 'F' THEN CASE WHEN PC3 = 'N' THEN 1 ELse 2 END
																			WHEN pc2 = 'Y' THEN CASE WHEN PC3 = 'A' THEN 1 ELSE 2 END
																			WHEN pc2 = 'D' THEN 3
																			ELSE 4 
																	   END
								WHEN event.EventType = 'Mens Basketball' THEN CASE WHEN fts.dimtickettypeid NOT IN (5,6,7) THEN 4
																				   WHEN RIGHT(pricecode,1) = 'D' THEN 3
																				   WHEN RIGHT(pricecode,1) = 'R' OR RIGHT(pricecode,2) IN ('HL', 'FS', 'LH') THEN 2
																				   ELSE 1
																			  END
							END
FROM #stgfactticketsales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE event.EventType IN ( 'Football', 'Mens Basketball')

/*===============================================================================================
											SEAT TYPE
===============================================================================================*/

UPDATE fts
SET fts.DimSeatTypeId = seattype.dimseattypeid
FROM #stgfactticketsales fts
	JOIN #events event ON event.DimeventId = fts.DimeventId
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
	JOIN ( SELECT EventType, PC1, DimSeatTypeId 
		   FROM (SELECT 'A' AS PC1,	1  dimseattypeid
				 UNION ALL SELECT 'B' AS PC1,	2  
				 UNION ALL SELECT 'C' AS PC1,	3  
				 UNION ALL SELECT 'D' AS PC1,	4  
				 UNION ALL SELECT 'E' AS PC1,	5  
				 UNION ALL SELECT 'F' AS PC1,	6  
				 UNION ALL SELECT 'G' AS PC1,	7  
				 UNION ALL SELECT 'H' AS PC1,	8  
				 UNION ALL SELECT 'I' AS PC1,	9  
				 UNION ALL SELECT 'J' AS PC1,	10 
				 UNION ALL SELECT 'K' AS PC1,	11 
				 UNION ALL SELECT 'L' AS PC1,	12 
				 UNION ALL SELECT 'S' AS PC1,	13
				 )a
				 CROSS JOIN (SELECT 'Football' AS EventType
							 UNION ALL SELECT 'Football Chairbacks'
							 )b

			UNION ALL

			SELECT 'Mens Basketball' EventType,  'A' PC1, 14 dimseattypeid
			UNION ALL SELECT 'Mens Basketball' EventType,  'B',15
			UNION ALL SELECT 'Mens Basketball' EventType,  'C',16
			UNION ALL SELECT 'Mens Basketball' EventType,  'D',17
			UNION ALL SELECT 'Mens Basketball' EventType,  'E',18
			UNION ALL SELECT 'Mens Basketball' EventType,  'F',19
			UNION ALL SELECT 'Mens Basketball' EventType,  'G',20
			UNION ALL SELECT 'Mens Basketball' EventType,  'H',21
			UNION ALL SELECT 'Mens Basketball' EventType,  'I',22
		 )seattype ON seattype.EventType = event.EventType
					  AND seattype.PC1 = dpc.PC1
							





/*===============================================================================================
											FACT TAGS
===============================================================================================*/
--leaving these blank for now and will populate as the use case arises




DROP TABLE #Events
DROP TABLE #StudentSeasons

END














GO

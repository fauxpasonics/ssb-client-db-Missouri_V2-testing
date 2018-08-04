SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


















CREATE PROCEDURE [etl].[Cust_FactTicketSalesProcessing]
(
	@BatchId INT = 0,
	@LoadDate DATETIME = NULL,
	@Options NVARCHAR(MAX) = NULL
)
AS

BEGIN

/*===============================================================================================
												EVENTS
===============================================================================================*/
--football are the only seasons that have been fleshed out so far for ticket types, more sports will need
--added as the rules are passed along

select CASE WHEN EventName LIKE '%chairbacks' THEN 'Football Chairbacks'
			WHEN seasonname = concat(seasonyear,' Mizzou Football') THEN 'Football'
			WHEN SeasonName = concat(seasonyear-1,'-',RIGHT(seasonyear,2),' Mizzou Men''s Basketball') THEN 'Mens Basketball'
			WHEN SeasonName = concat(seasonyear-1,'-',RIGHT(seasonyear,2),' Missouri Men''s Basketball') THEN 'Mens Basketball'
			WHEN seasonname = concat(seasonyear,' Student Tickets') THEN 'Student'
	   END AS EventType
	   , ds.SeasonYear
	   , ds.DimSeasonId
	   , de.DimEventId
INTO #Events 
FROM dimseason ds (NOLOCK)
	JOIN dbo.DimEvent de (NOLOCK) ON de.DimSeasonId = ds.DimSeasonId
								     OR de.DimEventId = 0	--unexpanded plans
where seasonname = concat(seasonyear,' Mizzou Football') --football
	  OR ds.SeasonName = concat(seasonyear-1,'-',RIGHT(seasonyear,2),' Mizzou Men''s Basketball') --Mens Basketball
	  OR SeasonName = concat(seasonyear-1,'-',RIGHT(seasonyear,2),' Missouri Men''s Basketball')
	  OR seasonname = concat(seasonyear,' Student Tickets')


/*===============================================================================================
											TICKET TYPE
===============================================================================================*/

--Full Season
UPDATE fts
SET fts.DimTicketTypeId = 5
FROM #stgFactTicketSales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId AND event.dimSeasonID = fts.DimSeasonID
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE   (event.EventType = 'Football' 
	     AND (
				RIGHT(PriceCode,LEN(PriceCode)-1) IN ('BR','C','CM','D','FC','FN','FR','M','N','PR','R','VM','X','DC','GIK','MC','BF3','BF4','BT3','BT4','BUP','TDT') 
				OR (Seasonyear IN (2016,2017,2018) AND PriceCode = 'AG')
			 )
	     AND PriceCode NOT IN ('EG','SC')
		 )
	  OR (event.EventType = 'Mens Basketball' 
		  AND (
				RIGHT(dpc.PriceCode, LEN(dpc.PriceCode) - 1) IN ('BC','C','D','FH','FP','L','LA','LC','M','N','R','SR','LN','LR')
				OR PriceCode = 'HSC'
			  )
		  )

--Partial Plan
UPDATE fts
SET fts.DimTicketTypeId = 6
FROM #stgFactTicketSales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId AND event.dimSeasonID = fts.DimSeasonID
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE (event.EventType = 'Football' AND (RIGHT(PriceCode,LEN(PriceCode)-1) IN ('MIZ','TIG','ZOU') OR PC2 = '3'))
	  OR (event.EventType = 'Mens Basketball' AND RIGHT(dpc.PriceCode, LEN(dpc.PriceCode) - 1) IN ('4','F','SEC'))




--Faculty/Staff
UPDATE fts
SET fts.DimTicketTypeId = 7
FROM #stgFactTicketSales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId AND event.dimSeasonID = fts.DimSeasonID
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE (event.EventType = 'Football' AND RIGHT(PriceCode,LEN(PriceCode)-1) IN ('FS','FN','AD'))
	  OR (event.EventType = 'Mens Basketball' AND RIGHT(dpc.PriceCode, LEN(dpc.PriceCode) - 1) IN ('FN','FS','LH'))

--Single
UPDATE fts
SET fts.DimTicketTypeId = 8
FROM #stgFactTicketSales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId AND event.dimSeasonID = fts.DimSeasonID
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE (event.EventType = 'Football' AND (RIGHT(PriceCode,LEN(PriceCode)-1) IN ('15','CS','G25','M','P','P2','S','T','H','','G1','G2','TD','FP','SC','BL','FA','FD','FV','TC','K','SK','F','G20','GB','SF','TK') OR  PriceCode IN ('EG','SC'))
									AND PriceCode <> 'S')
	  OR (event.EventType = 'Mens Basketball' AND RIGHT(dpc.PriceCode, LEN(dpc.PriceCode) - 1) IN ('','5','BY','P','RR','S','SC','SF','SG','SS','SW','V','W') AND PriceCode <> 'HSC')


--Student
UPDATE fts
SET fts.DimTicketTypeId = 9
FROM #stgFactTicketSales fts	
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
	JOIN #events event ON event.DimeventId = fts.DimeventId AND event.dimSeasonID = fts.DimSeasonID
WHERE event.EventType = 'Student'
	  OR (event.EventType = 'Mens Basketball' AND RIGHT(dpc.PriceCode, LEN(dpc.PriceCode) - 1) IN ('SI'	,'SO'))
	  OR (event.EventType = 'Football' AND PriceCode = 'S')


--Young Alum
UPDATE fts
SET fts.DimTicketTypeId = 10
FROM #stgFactTicketSales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId AND event.dimSeasonID = fts.DimSeasonID
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE event.EventType = 'Football' AND RIGHT(PriceCode,LEN(PriceCode)-1) IN ('Y2','Y3','YA','YS','YN')


--Chair Backs
UPDATE fts
SET fts.DimTicketTypeId = 11
FROM #stgFactTicketSales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId AND event.dimSeasonID = fts.DimSeasonID
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE event.EventType = 'Football Chairbacks'

--Group
UPDATE fts
SET fts.DimTicketTypeId = 12
FROM #stgFactTicketSales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId AND event.dimSeasonID = fts.DimSeasonID
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId
WHERE (event.EventType IN ('Mens Basketball') AND RIGHT(PriceCode,LEN(PriceCode)-1) = 'G')
	OR (event.EventType IN ('Football') AND RIGHT(PriceCode,LEN(PriceCode)-1) = 'G' AND NOT (Seasonyear IN (2016,2017,2018) AND PriceCode = 'AG'))

--Inventory
UPDATE fts
SET fts.DimTicketTypeId = 13
FROM #stgFactTicketSales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId AND event.dimSeasonID = fts.DimSeasonID
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
	
UPDATE fts
SET fts.DimPlanTypeId =	  CASE WHEN dimtickettypeid IN (5,6,7,10) 
							   THEN    CASE WHEN event.EventType = 'Football' THEN CASE WHEN pc2 = 'N' THEN 1
																						WHEN PriceCode = 'EM' THEN 1
																						WHEN pc2 = 'R' THEN 2
																						WHEN PriceCode = 'LBR' THEN 2
																						WHEN PriceCode = 'AVM' THEN 2
																						WHEN pc2 = 'F' THEN CASE WHEN PC3 = 'N' THEN 1 ELse 2 END
																						WHEN pc2 = 'Y' THEN CASE WHEN PC3 = 'A' THEN 1 ELSE 2 END
																						WHEN pc2 = 'D' THEN 3
																						ELSE 1
																					END
											WHEN event.EventType = 'Mens Basketball' THEN CASE WHEN RIGHT(pricecode,1) = 'D' THEN 3
																								WHEN RIGHT(pricecode,1) = 'R' OR RIGHT(pricecode,2) IN ('HL', 'FS', 'LH') THEN 2
																								ELSE 1
																						  END
										END
								ELSE 4
							END
FROM #stgFactTicketSales fts	
	JOIN #events event ON event.DimeventId = fts.DimeventId AND event.dimSeasonID = fts.DimSeasonID
	JOIN dbo.DimPriceCode dpc ON dpc.DimPriceCodeId = fts.DimPriceCodeId

/*===============================================================================================
											SEAT TYPE
===============================================================================================*/
/*
DimSeatTypeId	SeatTypeName
1				FB - LL - Sideline	
2				FB - Tiger Zone	
3				FB - Tiger Deck 1-4	
4				FB - TIger Deck 5-16	
5				FB - Rock M Hill	
6				FB - Touchdown Terrace	
7				FB - Tiger Lounge	
8				FB - Suites	
9				FB - West Club	
10				FB - East Club	
11				FB - East Loge	
12				FB - Accessible	
13				FB - Students	
14				MB - Tiger Row	
15				MB - Club	
16				MB - Side Court	
17				MB - Lower Corner	
18				MB - Upper Side	
19				MB - Upper Level	
20				MB - Upper Corner	
21				MB - Suite	
22				MB - Student	
*/


UPDATE fts
SET fts.DimSeatTypeId = seattype.dimseattypeid
FROM #stgFactTicketSales fts
	JOIN #events event ON event.DimeventId = fts.DimeventId AND event.dimSeasonID = fts.DimSeasonID
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

END

















GO

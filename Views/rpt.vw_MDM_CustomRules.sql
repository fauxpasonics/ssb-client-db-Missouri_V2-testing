SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [rpt].[vw_MDM_CustomRules]
 AS 

SELECT dimcustomerid
	  ,MAX(CASE WHEN dimtickettypeid IN (5,7,10) THEN CalDate END) LastPurchase_STH
	  ,MAX(CASE WHEN dimtickettypeid = 6 THEN CalDate END) LastPurchase_Partial
	  ,MAX(CalDate) LastPurchase
FROM factticketsales fts
	JOIN dbo.DimDate dimDate ON dimDate.DimDateId = fts.dimdateid
GROUP BY DimCustomerId
GO

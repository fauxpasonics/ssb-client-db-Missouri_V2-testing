SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [etl].[vwCRMProcess_SeasonTicketHolders]
AS

SELECT DISTINCT fts.SSID_acct_id SSID
, ds.seasonyear SeasonYear
, ds.seasonyear SeasonYr
FROM dbo.FactTicketSales fts
	JOIN dbo.DimSeason ds ON ds.DimSeasonId = fts.dimseasonid
WHERE fts.DimTicketTypeId = 5 --full season




GO

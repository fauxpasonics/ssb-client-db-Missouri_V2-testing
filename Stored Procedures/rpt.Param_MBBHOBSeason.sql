SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [rpt].[Param_MBBHOBSeason] AS

SELECT '2018' Label, '2018' Value
UNION ALL 
SELECT '2019' Label, '2019' Value

GO
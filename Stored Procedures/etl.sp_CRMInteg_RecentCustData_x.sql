SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




create PROCEDURE [etl].[sp_CRMInteg_RecentCustData_x]
AS

DECLARE @Client VARCHAR(50) = 'Mizzou'
DECLARE @TicketingCutoff DATE = DATEADD(YEAR,-3,GETDATE())


TRUNCATE TABLE etl.CRMProcess_RecentCustData

INSERT INTO etl.CRMProcess_RecentCustData
(
    SSID,
    MaxTransDate,
    Team,
    LoadDate
)

SELECT x.SSID, @Client Team, GETDATE() LoadDate, MAX(x.transdate) maxtransdate
	FROM (

		--Ticketing
		SELECT dc.ssid
			 , dimdate.CalDate TransDate
		FROM dbo.FactTicketSales fts 
			JOIN dbo.DimDate dimdate ON dimdate.DimDateId = fts.DimDateId
			JOIN dbo.DimCustomer dc  ON dc.DimCustomerId = fts.DimCustomerId
									 AND dc.CustomerType = 'Primary'
		WHERE dimdate.CalDate >= @TicketingCutoff
		
		UNION ALL
		
		--Ticket Exchange
		SELECT SSID
			  ,CreatedDate TransDate
		FROM ods.TM_Tex tex
			JOIN dbo.DimCustomer dc ON dc.AccountId = tex.assoc_acct_id
		WHERE dc.SourceSystem = 'tm'
			  AND dc.CustomerType = 'primary'
			  AND add_datetime >= @TicketingCutoff
			  AND activity_name IN ( 'TE Resale'
									,'Forward'
									,'Retail Forward'
									,'Retail Resale')

		UNION ALL
		
		--Donations
		SELECT dc.SSID
			 , donor.pledge_datetime TransDate
        FROM dbo.dimcustomer dc
        JOIN ods.TM_Donation donor ON dc.AccountId = donor.acct_id
        WHERE donor.pledge_datetime >= @TicketingCutoff
		
		) x
GROUP BY x.SSID


GO

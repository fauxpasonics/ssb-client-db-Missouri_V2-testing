SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- Author name: Jeff Barberio

-- Created date: 7/1/2017

-- Purpose: Manual Dimcustomer Load view for adhoc loads

-- Copyright © 2018, SSB, All Rights Reserved

-------------------------------------------------------------------------------

-- Modification History --

-- 6/22/2018: Jeff Barberio

	-- Change notes: Added in a filter for non-primary customers with donations
	
	-- Peer reviewed by: Abbey Meitin
	
	-- Peer review notes: 
	
	-- Peer review date: 6/22/2018
	
-- 7/5/2018: Abbey Meitin

	-- Change notes: Reduced @TicketingCutoff date from 3 years to 1 year per client request.
	
	-- Peer reviewed by: Jeff Barberio
	
	-- Peer review notes: 
	
	-- Peer review date: 7/5/2018


-------------------------------------------------------------------------------

-------------------------------------------------------------------------------



CREATE PROCEDURE [etl].[sp_CRMInteg_RecentCustData]
AS

DECLARE @Client VARCHAR(50) = 'Mizzou'
DECLARE @TicketingCutoff DATE = DATEADD(YEAR,-1,GETDATE()) --AMeitin: 7/5/2018 reduced to one year from 3


TRUNCATE TABLE etl.CRMProcess_RecentCustData


SELECT dimcustomerid, x.SSID, MAX(x.transdate) maxtransdate, @Client Team
INTO [#tmpTicketSales]
	FROM (

		--Ticketing
		SELECT dc.dimcustomerid,  dc.ssid
			 , dimdate.CalDate TransDate, @Client Team
		FROM dbo.FactTicketSales fts  WITH (NOLOCK)
			JOIN dbo.DimDate dimdate  WITH (NOLOCK) ON dimdate.DimDateId = fts.DimDateId
			JOIN dbo.DimCustomer dc WITH (NOLOCK)  ON dc.DimCustomerId = fts.DimCustomerId
									 AND dc.CustomerType = 'Primary'
		WHERE dimdate.CalDate >= @TicketingCutoff
		
		UNION ALL
		
		--Ticket Exchange
		SELECT dc.dimcustomerid, dc.SSID
			  ,CreatedDate TransDate, @Client
		FROM ods.TM_Tex tex WITH (NOLOCK)
			JOIN dbo.DimCustomer dc WITH (NOLOCK) ON dc.AccountId = tex.assoc_acct_id
		WHERE dc.SourceSystem = 'tm'
			  AND dc.CustomerType = 'primary'
			  AND add_datetime >= @TicketingCutoff
			  AND activity_name IN ( 'TE Resale'
									,'Forward'
									,'Retail Forward'
									,'Retail Resale')

		UNION ALL
		
		--Donations
		SELECT dc.DimCustomerId, dc.SSID
			 , donor.pledge_datetime TransDate, @Client
        FROM dbo.dimcustomer dc WITH (NOLOCK)
        JOIN ods.TM_Donation donor WITH (NOLOCK) ON dc.AccountId = donor.acct_id
        WHERE donor.pledge_datetime >= @TicketingCutoff
			  AND dc.CustomerType = 'primary'

		UNION ALL

		--Data Uploader Lists
		SELECT dc.DimCustomerID, dc.ssid, MAX(CreatedDate) MaxTransDate , @Client Team
		--Select distinct sourcesystem
		FROM  dbo.DimCustomer dc (NOLOCK)
		WHERE (SourceSystem LIKE 'MizzouUpload_%' 
		AND (dc.CreatedDate >= GETDATE() -10 OR dc.UpdatedDate >= GETDATE() -10))
		GROUP BY dc.DimCustomerId, dc.SSID

		
		) x
GROUP BY x.SSID, x.DimCustomerId


INSERT INTO etl.CRMProcess_RecentCustData (dimcustomerid, SSID, MaxTransDate, Team)
SELECT a.dimcustomerid, b.SSID, [MaxTransDate], Team
FROM	[#tmpTicketSales] a
	INNER JOIN dbo.[vwDimCustomer_ModAcctId] b ON [b].[DimCustomerId] = [a].[DimCustomerId];

DROP TABLE #tmpTicketSales;


GO

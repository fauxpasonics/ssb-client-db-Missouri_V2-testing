SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vwCRMLoad_TicketTransactions] AS 

SELECT  'Missouri'											AS Team__c --updateme
      , fts.ArchticsAccountId								AS TicketingAccountID__c
      , fts.SeasonName										AS SeasonName__c
	  , fts.FactTicketSalesId								AS FactTicketSalesID__c
      , fts.OrderNum										AS OrderNumber__c
      , fts.OrderLineItem									AS OrderLine__c
      , fts.TransDateTime									AS OrderDate__c
      , fts.ItemCode										AS Item__c
      , fts.ItemName										AS ItemName__c
	  , fts.EventDate										AS EventDate__c
      , fts.PriceCode										AS PriceCode__c
      , fts.IsComp											AS IsComp__c
      , fts.PromoCode										AS PromoCode__c
      , fts.QtySeat											AS QtySeat__c
      , fts.SectionName										AS SectionName__c
      , fts.RowName											AS RowName__c
      , fts.Seat											AS Seat__c
      , fts.BlockFullPrice									AS SeatPrice__c
      , fts.BlockPurchasePrice								AS Total__c
      , fts.OwedAmount										AS OwedAmount__c
      , fts.PaidAmount										AS PaidAmount__c
	  , fts.DimCustomerId_TransSalesRep						AS SalesRep__c
FROM   [dbo].[vw_FactTicketSalesBase] fts
INNER JOIN [dbo].[vwDimCustomer_ModAcctId] dc on dc.SourceSystem = 'TM' AND dc.AccountId = fts.ArchticsAccountId AND dc.CustomerType = 'Primary'





GO

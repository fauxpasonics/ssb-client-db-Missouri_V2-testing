CREATE TABLE [segmentation].[SegmentationFlatDatac28f4671-34d1-4d8e-9d7b-b377875bbfcb]
(
[id] [uniqueidentifier] NOT NULL,
[DocumentType] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SessionId] [varchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Environment] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TenantId] [varchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[_rn] [bigint] NULL,
[SSB_CRMSYSTEM_CONTACT_ID] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SFDC_ContactID] [nvarchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SFDC_AccountID] [nvarchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Name] [nvarchar] (121) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedDate] [datetime] NULL,
[CreatedById] [nvarchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedByName] [nvarchar] (121) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastModifiedDate] [datetime] NULL,
[LastModifiedById] [nvarchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OwnerId] [nvarchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OwnerName] [nvarchar] (121) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastActivityDate] [date] NULL,
[DaysSinceLastActivity] [int] NULL,
[HasOpenOpportunity] [int] NULL,
[LastOpportunityCreatedDate] [date] NULL,
[LastOpportunityOwnerName] [nvarchar] (121) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastOpportunityLastModifiedDate] [date] NULL,
[LastOpportunityClosedWonDate] [date] NULL,
[LastOpportunityClosedLostReason] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastTicketPurchaseDate] [date] NULL,
[LastDonationDate] [date] NULL,
[DonorWarningFlag] [bit] NULL,
[TotalPriorityPoints] [float] NULL,
[FootballSTH] [bit] NULL,
[FootballRookie] [bit] NULL,
[FootballPartial] [bit] NULL,
[MBBSTH] [bit] NULL,
[MBBRookie] [bit] NULL,
[MBBPartial] [bit] NULL,
[CY_DonationLevel] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CY_DonationAmount] [float] NULL,
[CY_DonationUpsell] [float] NULL,
[CorporateBuyerFlag] [bit] NULL,
[CompanyName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
GO
ALTER TABLE [segmentation].[SegmentationFlatDatac28f4671-34d1-4d8e-9d7b-b377875bbfcb] ADD CONSTRAINT [pk_SegmentationFlatDatac28f4671-34d1-4d8e-9d7b-b377875bbfcb] PRIMARY KEY NONCLUSTERED  ([id])
GO
CREATE CLUSTERED INDEX [cix_SegmentationFlatDatac28f4671-34d1-4d8e-9d7b-b377875bbfcb] ON [segmentation].[SegmentationFlatDatac28f4671-34d1-4d8e-9d7b-b377875bbfcb] ([_rn])
GO

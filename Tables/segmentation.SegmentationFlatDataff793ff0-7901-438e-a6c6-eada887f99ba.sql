CREATE TABLE [segmentation].[SegmentationFlatDataff793ff0-7901-438e-a6c6-eada887f99ba]
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
[IsDonor] [bit] NULL,
[LastDonationDate] [datetime] NULL,
[LastPurchaseDate] [datetime] NULL,
[FB_PartialBuyer] [bit] NULL,
[FB_STH] [bit] NULL,
[FB_STH_Rookie] [bit] NULL,
[PriorityPoints] [float] NULL
)
GO
ALTER TABLE [segmentation].[SegmentationFlatDataff793ff0-7901-438e-a6c6-eada887f99ba] ADD CONSTRAINT [pk_SegmentationFlatDataff793ff0-7901-438e-a6c6-eada887f99ba] PRIMARY KEY NONCLUSTERED  ([id])
GO
CREATE CLUSTERED INDEX [cix_SegmentationFlatDataff793ff0-7901-438e-a6c6-eada887f99ba] ON [segmentation].[SegmentationFlatDataff793ff0-7901-438e-a6c6-eada887f99ba] ([_rn])
GO

CREATE TABLE [segmentation].[SegmentationFlatData2b82747c-18ed-482b-9ff9-e820629fa646]
(
[id] [uniqueidentifier] NOT NULL,
[DocumentType] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SessionId] [varchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Environment] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TenantId] [varchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[_rn] [bigint] NULL,
[SSB_CRMSYSTEM_CONTACT_ID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerSourceSystem] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
GO
ALTER TABLE [segmentation].[SegmentationFlatData2b82747c-18ed-482b-9ff9-e820629fa646] ADD CONSTRAINT [pk_SegmentationFlatData2b82747c-18ed-482b-9ff9-e820629fa646] PRIMARY KEY NONCLUSTERED  ([id])
GO
CREATE CLUSTERED INDEX [cix_SegmentationFlatData2b82747c-18ed-482b-9ff9-e820629fa646] ON [segmentation].[SegmentationFlatData2b82747c-18ed-482b-9ff9-e820629fa646] ([_rn])
GO

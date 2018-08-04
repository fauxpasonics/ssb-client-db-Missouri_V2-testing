CREATE TABLE [segmentation].[SegmentationFlatData5f47d4c6-f3cf-49e6-bfdb-9c00be1637f8]
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
ALTER TABLE [segmentation].[SegmentationFlatData5f47d4c6-f3cf-49e6-bfdb-9c00be1637f8] ADD CONSTRAINT [pk_SegmentationFlatData5f47d4c6-f3cf-49e6-bfdb-9c00be1637f8] PRIMARY KEY NONCLUSTERED  ([id])
GO
CREATE CLUSTERED INDEX [cix_SegmentationFlatData5f47d4c6-f3cf-49e6-bfdb-9c00be1637f8] ON [segmentation].[SegmentationFlatData5f47d4c6-f3cf-49e6-bfdb-9c00be1637f8] ([_rn])
GO

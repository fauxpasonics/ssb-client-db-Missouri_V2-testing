CREATE TABLE [segmentation].[SegmentationFlatData8f2ec1ee-d0e6-4972-8373-cbf8736750fc]
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
ALTER TABLE [segmentation].[SegmentationFlatData8f2ec1ee-d0e6-4972-8373-cbf8736750fc] ADD CONSTRAINT [pk_SegmentationFlatData8f2ec1ee-d0e6-4972-8373-cbf8736750fc] PRIMARY KEY NONCLUSTERED  ([id])
GO
CREATE CLUSTERED INDEX [cix_SegmentationFlatData8f2ec1ee-d0e6-4972-8373-cbf8736750fc] ON [segmentation].[SegmentationFlatData8f2ec1ee-d0e6-4972-8373-cbf8736750fc] ([_rn])
GO

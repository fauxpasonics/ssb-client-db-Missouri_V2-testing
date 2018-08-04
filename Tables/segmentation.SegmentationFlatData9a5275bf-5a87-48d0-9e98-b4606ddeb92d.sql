CREATE TABLE [segmentation].[SegmentationFlatData9a5275bf-5a87-48d0-9e98-b4606ddeb92d]
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
ALTER TABLE [segmentation].[SegmentationFlatData9a5275bf-5a87-48d0-9e98-b4606ddeb92d] ADD CONSTRAINT [pk_SegmentationFlatData9a5275bf-5a87-48d0-9e98-b4606ddeb92d] PRIMARY KEY NONCLUSTERED  ([id])
GO
CREATE CLUSTERED INDEX [cix_SegmentationFlatData9a5275bf-5a87-48d0-9e98-b4606ddeb92d] ON [segmentation].[SegmentationFlatData9a5275bf-5a87-48d0-9e98-b4606ddeb92d] ([_rn])
GO

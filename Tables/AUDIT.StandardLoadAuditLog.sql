CREATE TABLE [AUDIT].[StandardLoadAuditLog]
(
[StandardLoadAuditLogID] [int] NOT NULL IDENTITY(1, 1),
[LoadDate] [datetime] NULL,
[LoadView] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LoadGuid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RecordCount] [int] NULL
)
GO
ALTER TABLE [AUDIT].[StandardLoadAuditLog] ADD CONSTRAINT [PK__Standard__91742232B244D9C2] PRIMARY KEY CLUSTERED  ([StandardLoadAuditLogID])
GO

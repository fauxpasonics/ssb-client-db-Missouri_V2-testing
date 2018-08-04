CREATE TABLE [etl].[LogTable]
(
[LogId] [bigint] NOT NULL IDENTITY(1, 1),
[EventDate] [datetime] NOT NULL,
[BatchId] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UserName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Logger] [nvarchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Level] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Message] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
GO

CREATE TABLE [etl].[tmp_privacy_C7F6B997C3774525B996A180144285EF]
(
[SessionID] [uniqueidentifier] NULL,
[RecordCreatedDate] [datetime] NULL,
[Processed] [bit] NULL,
[DimCustomerID] [int] NULL,
[SSID] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SourceSystem] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Verified_Consent_TS] [datetime] NULL,
[Verified_Consent_Source] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Data_Deletion_Request_TS] [datetime] NULL,
[Data_Deletion_Request_Reason] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Data_Deletion_Request_Source] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Subject_Access_Request_TS] [datetime] NULL,
[Subject_Access_Request_Source] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Direct_Marketing_OptOut_TS] [datetime] NULL,
[Direct_Marketing_OptOut_Reason] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Direct_Marketing_OptOut_Source] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RecordRank] [bigint] NULL
)
GO

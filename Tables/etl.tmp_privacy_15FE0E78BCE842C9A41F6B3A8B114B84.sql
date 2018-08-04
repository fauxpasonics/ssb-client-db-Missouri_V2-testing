CREATE TABLE [etl].[tmp_privacy_15FE0E78BCE842C9A41F6B3A8B114B84]
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

CREATE TABLE [stg].[TM_Journal]
(
[ETL__ID] [int] NOT NULL IDENTITY(1, 1),
[ETL__CreatedDate] [datetime] NULL CONSTRAINT [DF_TM_Journal_ETL__CreatedDate] DEFAULT (getdate()),
[ETL__Source] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[acct_id] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stamp] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seq] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_desc] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[debit] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[credit] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invoice_amount] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[event_id] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_num] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_line_item] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_line_item_seq] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cc_type] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[payment_type_desc] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[payment_schedule_id] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invoice_id] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[journal_seq_id] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[teamname] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[add_user] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[upd_user] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[credit_applied] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[batch_tag] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[batch_id] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cc_num_masked] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[surchg_amount] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[surchg_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[disc_amount] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[disc_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ledger_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[merchant_code] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plan_event_name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[event_name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[section_name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seat_num] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_seat] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sell_location] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[info] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[posted_date] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seq_num] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
GO

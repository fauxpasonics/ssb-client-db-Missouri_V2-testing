SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [ods].[TM_vw_Ticket_QA] AS (

SELECT a.*
FROM ods.TM_vw_TicketActive a
	JOIN ods.TM_vw_TicketReturn r 
ON a.acct_id = r.acct_id 
	AND a.event_id = r.event_id
	AND a.section_id = r.section_id
	AND a.row_id = r.row_id
	AND a.seat_num = r.seat_num
	AND a.order_num <= r.order_num
	AND a.order_line_item <= r.order_line_item
	AND a.add_datetime > ISNULL(r.add_datetime, '1900-01-01')


)



GO

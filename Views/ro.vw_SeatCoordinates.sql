SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [ro].[vw_SeatCoordinates]
AS
(
	SELECT 
		SectionName,
		RowName,
		Seat,
		X,
		Y
	FROM dbo.SeatCoordinates (NOLOCK)
)



GO

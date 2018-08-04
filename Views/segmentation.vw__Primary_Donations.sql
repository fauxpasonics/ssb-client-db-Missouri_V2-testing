SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [segmentation].[vw__Primary_Donations]

AS
(

SELECT dc.SSB_CRMSYSTEM_CONTACT_ID
	, don.acct_id Archtics_ID
	, don.Pledge_Datetime
	, don.Fund_ID
	, don.Fund_Name
	, don.Fund_Desc
	, don.Drive_Year
	, don.Donation_Type_Name
	, don.Solicitation_Name
	, don.Solicitation_Category_Name
	, don.Contact_Type
	, don.Gl_Code
	, don.Active
	, don.Qual_For_Benefits
	, don.Original_Pledge_Amount
	, don.Pledge_Amount
	, don.Donation_Paid_Amount
	, don.Total_Received_Amount
	, don.Owed_Amount
	, don.External_Paid_Amount
	, don.Donor_Level_Amount_Qual
	, don.Donor_Level_Amount_Not_Qual
	, don.Donor_Level_Amount_Qual_Apply_To_Acct
	, don.Donor_Level_Amount_Not_Qual_Apply_To_Acct
	, don.[Anonymous]
	, don.[Source]
	, don.[Points]
	, don.Donor_Level_Set_Name
	, COALESCE(dl.honorary_donor_level, dl.donor_level) Donor_Level
FROM ods.tm_donation don
JOIN ods.TM_CustDonorLevel dl ON don.apply_to_acct_id = dl.acct_id
	AND dl.drive_year = don.drive_year
JOIN (
		SELECT *
		FROM dbo.vwDimCustomer_ModAcctId
		WHERE sourcesystem = 'TM'
	) dc ON don.apply_to_acct_id = dc.AccountId
WHERE don.drive_year >= 2014
)
GO

USE [BIDataWarehouse]
GO

/****** Object:  StoredProcedure [dbo].[usp_ProfitandLoss_Dashboard]    Script Date: 24/11/2016 11:00:19 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE Procedure [dbo].[usp_ProfitandLoss_Dashboard] 
	@pCurrency varchar(5),
	@pFiscalPeriod int,
	@pLanguage int,
	@pOrg varchar(max) 

	
	AS 


Declare @FuncCurrency as Varchar(5);
Declare @ConsCurrency as Varchar(5);
Declare @ENLanguage as int;
Declare @FRLanguage as int;
Declare	@Template as int;
Declare @GroupID as int;
Declare @pInCurrency as varchar(5);
Declare @pInFiscalPeriod as int;
Declare @pInLanguage as int;
Declare @pInOrg as Varchar(max);

/**
Declare @pInCurrency as varchar(5);
declare	@pFiscalPeriod as int;
declare	@pTemplate as int;
declare	@pInLanguage as int;
Declare @pInOrg as Varchar(max);
**/

SET @FuncCurrency = 'FUNC';
SET @ConsCurrency = 'CONS';
SET @ENLanguage = 1;
SET @FRLanguage = 2;
SET @Template = 100
SET @GroupID = -24
SET @pInCurrency = @pCurrency
SET @pInFiscalPeriod = @pFiscalPeriod
SET @pInLanguage = @pLanguage
SET @pInOrg = @pOrg



/**
SET @pFiscalPeriod = 201605;
Set @pTemplate = 105;
SET @pInLanguage = 1;
SET @pInCurrency = 'FUNC';
SET @pInOrg = '452,662,453,387';
SET @pInCurrency = 'CONS';
**/


BEGIN

		WITH ProfitandLossCTE (TemplateID
					,GroupID,GroupDesc, FiscalYear,PostPeriodSkey
					,FiscalPeriodNumber,SortOrder,FiscalPeriodShortName, FiscalPeriodLongName
					,[Current Month Amount],[YTD Amount]
					
					)
		AS
		(  
			SELECT  FT.TemplateID				 
					,FT.GroupID 
					, Case @pInLanguage When @ENLanguage THEN FT.GroupDescEN 
									  WHEN @FRLanguage THEN FT.GroupDescFR
									  Else 'Unknown'
						END as GroupDesc
					,CP.FiscalYear
					,PostPeriodSkey
					,FiscalPeriodNumber
					,SortOrder
					,Case @pInLanguage When @ENLanguage THEN CP.FiscalPeriodShortNameEN 
									  WHEN @FRLanguage THEN CP.FiscalPeriodShortNameFR
									  Else 'Unknown'
						END as FiscalPeriodShortName
					,Case @pInLanguage When @ENLanguage THEN CP.FiscalPeriodLongNameEN 
									  WHEN @FRLanguage THEN CP.FiscalPeriodLongNameFR
									  Else 'Unknown'
						END as FiscalPeriodLongName
					
					,ISNULL( Case @pInCurrency  WHEN @ConsCurrency THEN SUM(PL.ConsCMAmt * FT.IncomeStatementActualSign) 
									   WHEN @FuncCurrency THEN SUM(PL.FuncCMAmt * FT.IncomeStatementActualSign)
									   Else 0.000000
					  END,0.000000) as [Current Month Amount]
					
					, ISNULL(Case @pInCurrency  WHEN @ConsCurrency THEN SUM(PL.ConsYTDAmt * FT.IncomeStatementActualSign)
										WHEN @FuncCurrency THEN SUM(PL.FuncYTDAmt * FT.IncomeStatementActualSign)
										Else 0.000000
						END,0.000000) as [YTD Amount]
					
		
	
		FROM        FactProfitAndLossSummary   AS PL 
				LEFT OUTER JOIN MapFinancialTemplate as FT   ON FT.AccountSkey = PL.AccountSkey 
				INNER JOIN [dbo].[DimOrganization] as DO ON PL.OrgSkey = DO.OrgSkey
				INNER JOIN DimCalendarPeriod AS CP ON PL.PostPeriodSkey = CP.FiscalPeriodSkey
		WHERE     PL.PostPeriodSkey BETWEEN  Convert(INT, Convert(varchar(6),Dateadd(mm, -12, Convert(Date, Convert(varchar(8),((@pInFiscalPeriod * 100) +1)),112)),112)) 
									AND @pInFiscalPeriod
					AND (FT.TemplateID = @Template)
					AND PL.OrgSkey IN	( Select * from dbo.STRING_SPLIT(@pInOrg, ','))
					AND ([IsNetRevenues] = 'Y' OR [IsDirectLabor] = 'Y' OR [IsEBGE] = 'Y' OR [IsEBITDA] = 'Y' OR FT.GroupID = @GroupID)
					  
		
			
		GROUP BY	 FT.TemplateID
					 
					,FT.GroupID
					,Case @pInLanguage When @ENLanguage THEN FT.GroupDescEN 
									  WHEN @FRLanguage THEN FT.GroupDescFR
									  Else 'Unknown'
						END
					,CP.FiscalPeriodNumber
					,CP.FiscalYear
					,PostPeriodSkey
					,SortOrder
					,Case @pInLanguage When @ENLanguage THEN CP.FiscalPeriodShortNameEN 
									  WHEN @FRLanguage THEN CP.FiscalPeriodShortNameFR
									  Else 'Unknown'
									  END
					,Case @pInLanguage When @ENLanguage THEN CP.FiscalPeriodLongNameEN 
									  WHEN @FRLanguage THEN CP.FiscalPeriodLongNameFR
									  Else 'Unknown'
									  END
						
			
			
		)
		Select * FROM
		(
		SELECT * FROM ProfitandLossCTE
		UNION 

		SELECT NR.TemplateID,
				Case  WA.GroupID WHEN -27 THEN  -28
						ELSE -1
						END AS GroupID

				, CASE WA.GroupDesc WHEN 'Direct Labor' THEN 'GM'
								ELSE 'Unknown'
								END AS GroupDesc
				, NR.FiscalYear, NR.PostPeriodSkey
				,NR.FiscalPeriodNumber, WA.SortOrder +10 , NR.FiscalPeriodShortName, WA.FiscalPeriodLongName
		,NR.[Current Month Amount] - WA.[Current Month Amount]
		
		,NR.[YTD Amount] - WA.[YTD Amount]
		FROM
		(SELECT * FROM ProfitandLossCTE
		WHERE GROUPID = 51)NR
		INNER JOIN (SELECT * FROM ProfitandLossCTE
		WHERE GROUPID = -27)WA ON NR.TemplateID = WA.TemplateID
								--AND NR.GroupID = WA.GroupID
								AND NR.PostPeriodSkey = WA.PostPeriodSkey
		)CD
		ORDER BY 	TemplateID
					,FiscalYear,PostPeriodSkey,SortOrder
		 
END

GO


SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE   FUNCTION [ods].[fn_validaRUC] (@ruc NVARCHAR(100))
RETURNS NVARCHAR(1)
AS BEGIN

  DECLARE @rucF AS NVARCHAR(1);

  SELECT @rucF = CASE
                   WHEN @ruc IS NULL THEN '0'
                   WHEN @ruc = '' THEN '0'
                   WHEN LEN(@ruc) <> 11 THEN '0'
                   WHEN REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE (@ruc, '0', ''),
                        '1', ''),
                        '2', ''),
                        '3', ''),
                        '4', ''),
                        '5', ''),
                        '6', ''),
                        '7', ''),
                        '8', ''),
                        '9', '') <> '' THEN '0'
                   WHEN (SUBSTRING(@ruc,1,2)=SUBSTRING(@ruc,3,2)) and (SUBSTRING(@ruc,1,2)=SUBSTRING(@ruc,5,2)) and (SUBSTRING(@ruc,1,2)=SUBSTRING(@ruc,7,2)) and (SUBSTRING(@ruc,1,2)=SUBSTRING(@ruc,9,2)) THEN '0'
                   WHEN @ruc like '10%' THEN '1'
                   WHEN @ruc like '20%' THEN '1'
                   WHEN @ruc like '15%' THEN '1'
                   WHEN @ruc like '16%' THEN '1'
                   WHEN @ruc like '17%' THEN '1'
                   ELSE '0'
  END
	RETURN @rucF
END
GO
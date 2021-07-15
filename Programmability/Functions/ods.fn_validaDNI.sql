SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE   FUNCTION [ods].[fn_validaDNI] (@dni NVARCHAR(100))
RETURNS NVARCHAR(1)
AS BEGIN

  DECLARE @dniF AS NVARCHAR(1);

  SELECT @dniF = CASE
                   WHEN @dni IS NULL THEN '0'
                   WHEN @dni = '' THEN '0'
                   WHEN LEN(@dni) <> 8 THEN '0'
                   WHEN @dni = '12345678' THEN '0'
                   WHEN @dni = '01234567' THEN '0'
                   WHEN @dni = '78945612' THEN '0'
                   WHEN @dni like '00%' THEN '0'
                   WHEN REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE (@dni, '0', ''),
                        '1', ''),
                        '2', ''),
                        '3', ''),
                        '4', ''),
                        '5', ''),
                        '6', ''),
                        '7', ''),
                        '8', ''),
                        '9', '') <> '' THEN '0'
                   WHEN (SUBSTRING(@dni,1,2)=SUBSTRING(@dni,3,2)) and (SUBSTRING(@dni,1,2)=SUBSTRING(@dni,5,2)) and (SUBSTRING(@dni,1,2)=SUBSTRING(@dni,7,2)) THEN '0'
                   ELSE '1'
  END
	RETURN @dniF
END
GO
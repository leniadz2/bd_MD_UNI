SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE   FUNCTION [ods].[fn_validaCE] (@ce NVARCHAR(100))
RETURNS NVARCHAR(1)
AS BEGIN

  DECLARE @ceF AS NVARCHAR(1);

  SELECT @ceF = CASE
                   WHEN @ce IS NULL THEN '0'
                   WHEN @ce = '' THEN '0'
                   WHEN LEN(@ce) <> 9 THEN '0'
                   WHEN (SUBSTRING(@ce,1,2)=SUBSTRING(@ce,3,2)) and (SUBSTRING(@ce,1,2)=SUBSTRING(@ce,5,2)) and (SUBSTRING(@ce,1,2)=SUBSTRING(@ce,7,2)) THEN '0'
                   WHEN (SUBSTRING(@ce,2,2)=SUBSTRING(@ce,4,2)) and (SUBSTRING(@ce,2,2)=SUBSTRING(@ce,6,2)) and (SUBSTRING(@ce,2,2)=SUBSTRING(@ce,8,2)) THEN '0'
                   ELSE '1'
  END
	RETURN @ceF
END
GO
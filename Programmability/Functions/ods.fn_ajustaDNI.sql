SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE FUNCTION [ods].[fn_ajustaDNI] (@dni NVARCHAR(48))
RETURNS NVARCHAR(50)
AS BEGIN

  DECLARE @dniF AS NVARCHAR(1);
  DECLARE @dni_RTRN AS NVARCHAR(50);
  DECLARE @dni_RTRN_F AS NVARCHAR(1);

  SELECT @dniF = CASE
                   WHEN @dni IS NULL THEN '0'
                   WHEN @dni = '' THEN '0'
                   WHEN LEN(@dni) > 8 THEN '0'
                   WHEN @dni = '12345678' THEN '0'
                   WHEN @dni = '01234567' THEN '0'
                   WHEN @dni = '78945612' THEN '0'
                   WHEN @dni = '87654321' THEN '0'
                   WHEN @dni = '98765432' THEN '0'
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
                   WHEN (SUBSTRING(@dni,2,2)=SUBSTRING(@dni,4,2)) and (SUBSTRING(@dni,2,2)=SUBSTRING(@dni,6,2)) and (SUBSTRING(@dni,2,2)=SUBSTRING(@dni,7,2)) THEN '0'
                   ELSE '1'
  END

  IF @dniF = 1
    IF LEN(@dni) = 8
      BEGIN
        SET @dni_RTRN_F = 1;
        SET @dni_RTRN = @dni;
      END;
    ELSE IF LEN(@dni) < 8
      BEGIN
        SET @dni_RTRN_F = ods.fn_validaDNI(RIGHT(CONCAT('00000000',@dni),8));
        SET @dni_RTRN = RIGHT(CONCAT('00000000',@dni),8);
      END;
    ELSE
      BEGIN
        SET @dni_RTRN_F = 0;
        SET @dni_RTRN = @dni;
      END;
  ELSE
    BEGIN
      SET @dni_RTRN_F = 0;
      SET @dni_RTRN = @dni;
    END;

	RETURN CONCAT(@dni_RTRN_F,'|',@dni_RTRN)

END
GO
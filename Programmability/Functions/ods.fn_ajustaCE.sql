SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE FUNCTION [ods].[fn_ajustaCE] (@ce NVARCHAR(48))
RETURNS NVARCHAR(50)
AS BEGIN

  /*FUENTE: https://sistemasdgc.rree.gob.pe/carext_consulta_webapp/?valS=aG9zdD1zaXN0ZW1hc2RnYy5ycmVlLmdvYi5wZSxrZXk9RVpQVUtCRldBUklNQ1RY*/

  DECLARE @ceF AS NVARCHAR(1);
  DECLARE @ce_RTRN AS NVARCHAR(50);
  DECLARE @ce_RTRN_F AS NVARCHAR(1);

  SELECT @ceF = CASE
                   WHEN @ce IS NULL THEN '0'
                   WHEN @ce = '' THEN '0'
                   WHEN LEN(@ce) > 8 THEN '0'
                   WHEN @ce = '12345678' THEN '0'
                   WHEN @ce = '01234567' THEN '0'
                   WHEN @ce = '78945612' THEN '0'
                   WHEN @ce = '87654321' THEN '0'
                   WHEN @ce = '98765432' THEN '0'
                   WHEN REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE
                        (REPLACE (@ce, '0', ''),
                        '1', ''),
                        '2', ''),
                        '3', ''),
                        '4', ''),
                        '5', ''),
                        '6', ''),
                        '7', ''),
                        '8', ''),
                        '9', '') <> '' THEN '0'
                   WHEN (SUBSTRING(@ce,1,2)=SUBSTRING(@ce,3,2)) and (SUBSTRING(@ce,1,2)=SUBSTRING(@ce,5,2)) and (SUBSTRING(@ce,1,2)=SUBSTRING(@ce,7,2)) THEN '0'
                   WHEN (SUBSTRING(@ce,2,2)=SUBSTRING(@ce,4,2)) and (SUBSTRING(@ce,2,2)=SUBSTRING(@ce,6,2)) and (SUBSTRING(@ce,2,2)=SUBSTRING(@ce,7,2)) THEN '0'
                   ELSE '1'
  END

  IF @ceF = 1
    IF LEN(@ce) = 8
      BEGIN
        SET @ce_RTRN_F = 1;
        SET @ce_RTRN = @ce;
      END;
    ELSE IF LEN(@ce) < 8
      BEGIN
        SET @ce_RTRN_F = ods.fn_validaCE(RIGHT(CONCAT('00000000',@ce),8));
        SET @ce_RTRN = RIGHT(CONCAT('00000000',@ce),8);
      END;
    ELSE
      BEGIN
        SET @ce_RTRN_F = 0;
        SET @ce_RTRN = @ce;
      END;
  ELSE
    BEGIN
      SET @ce_RTRN_F = 0;
      SET @ce_RTRN = @ce;
    END;

	RETURN CONCAT(@ce_RTRN_F,'|',@ce_RTRN)

END
GO
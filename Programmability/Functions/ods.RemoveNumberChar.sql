SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE   FUNCTION [ods].[RemoveNumberChar](@Temp VARCHAR(1000))
RETURNS VARCHAR(1000)
AS
BEGIN

    DECLARE @expres  VARCHAR(50) = '%[0-9]%'
    WHILE PATINDEX( @expres, @Temp ) > 0
      SET @Temp = Replace(REPLACE( @Temp, SUBSTRING( @Temp, PATINDEX( @expres, @Temp ), 1 ),''),'-',' ')

    RETURN @Temp
END;
GO
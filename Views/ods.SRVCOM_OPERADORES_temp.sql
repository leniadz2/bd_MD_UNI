SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE   VIEW [ods].[SRVCOM_OPERADORES_temp]
AS
SELECT DISTINCT
  RUCEMISOR
 ,CODIGOMALL
 ,CODIGOTIENDA
 ,CONTRATO_RE
FROM ini.SRVCOM_OPERADORES
GO
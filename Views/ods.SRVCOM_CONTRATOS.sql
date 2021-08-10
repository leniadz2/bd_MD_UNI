﻿SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE VIEW [ods].[SRVCOM_CONTRATOS]
AS
SELECT
  lo.AZU_IDGRCO AS CODIGOMALL
 ,lo.AZU_DESC_MED AS LOCACION_DESC
 ,rc.NIF AS RUCEMISOR
 ,rc.CONTRATO AS CONTRATO_RE
 ,rc.SOCIEDAD AS SAP_SOC
 ,rc.DEN_CONTRATO AS DENCONTRATO
 ,rc.NOMCOMERCIAL
 ,rc.OBJALQUILER
 ,rc.INI_CONTRATO_MOD AS CONTRATO_FECINI
 ,rc.FIN_CONTRATO_MOD AS CONTRATO_FECFIN
 ,rc.VIGCONTRATO
 ,rc.GAFO
 ,rc.SUBGAFO
FROM ods.RE_CONTRATOS rc
  LEFT JOIN ini.LYTY_ASOCIADO lo
    ON lo.SAP_SOC = rc.SOCIEDAD
WHERE rc.ORDINTERLOCCOMERCIAL = 1
GO
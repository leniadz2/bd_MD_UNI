SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [bds].[sp_srvlty]
AS
  /***************************************************************************************************
  Procedure:          [bds].sp_srvlty
  Create Date:        20210521
  Author:             dÁlvarez
  Description:        tabla final (a ser ingestada por SAC).
                      la tabla se exporta en CSV usando *> dbeaver <* con las sgtes caracteristicas:
                        delimiter: |
                        quote characters: "
                        quote always: string
                        null string: vacio
                        encoding: UTF-8

                      20210911: se debe exportar: bds.SRV_LYTY_dlt y guardar como SRV_LYTY.csv
                      **NOTA:: aquellos clientes con CODIGOPERSONA = '9999999999' provienen de un archivo plano externo

  Call by:            tbd
  Affected table(s):  bds.SRVLYTY
  Used By:            BI
  Parameter(s):       none
  Log:                none
  Prerequisites:      ods.sp_srvlty
                      proceso SAP
  ****************************************************************************************************
  SUMMARY OF CHANGES
  Date(YYYYMMDD)      Author              Comments
  ------------------- ------------------- ------------------------------------------------------------
  20210521            dÁlvarez            creación
  20210601            dÁlvarez            se unifican dos SP como mejora (se renombra sp_srvlty_SAC)
  20210610            dÁlvarez            se adiciona lógica del delta (para cargar a SAC)
  20210713            dÁlvarez            MD_UNI
  20210810            dÁlvarez            ajustes LTY/SRV/SRVLTY
  
  ***************************************************************************************************/
  --1024s
    TRUNCATE TABLE bds.SRVLYTY;

    INSERT INTO bds.SRVLYTY
    SELECT s.srv_ID
          ,s.srv_NOMBRE
          ,s.srv_RAZONSOCIAL
          ,s.srv_NOMBRETIENDA
          ,CONCAT(s.srv_CODIGOLOCACION,'|',IIF(rc.GAFO IS NULL,'0',rc.GAFO),'|',IIF(rc.SUBGAFO IS NULL,'0',rc.SUBGAFO),'|',s.srv_NOMBRETIENDA)  AS    srv_NOMBRETIENDA_ID
          ,s.srv_CODIGOLOCACION
          ,s.srv_CODIGOLOCACION_D
          ,s.srv_CODIGOTIENDA
          ,s.srv_RUCEMISOR
          ,s.srv_NUMEROTERMINAL
          ,s.srv_SERIE
          ,s.srv_TIPOTRANSACCION
          ,s.srv_NUMEROTRANSACCION
          ,s.FECHA_ID
          ,s.srv_HORA
          ,s.srv_HORAHH
          ,s.srv_HORAMI
          ,s.srv_HORA_RANGO
          ,s.srv_VENDEDOR
          ,s.srv_DNI
          ,s.srv_RUC
          ,s.srv_CE
          ,s.srv_DUIval
          ,s.srv_DUI
          ,s.srv_DUITIPO
          ,s.srv_NOMBRECLIENTE
          ,s.srv_DIRECCIONCLIENTE
          ,s.srv_BONUS
          ,s.srv_MONEDA
          ,s.srv_MEDIOPAGO
          ,s.srv_TOTVALORVTABRUTA
          ,s.srv_DESCUENTOSGLOBAL
          ,s.srv_MONTOTOTALIGV
          ,s.srv_TOTVALORVENTANETA
          ,s.srv_ORDENITEM
          ,s.srv_CANTUNIDADESITEM
          ,s.srv_CODIGOPRODUCTO
          ,s.srv_DESCRIPCIONPROD
          ,s.srv_PRECIOVTAUNITITEM
          ,s.srv_CARGODESCUENTOITEM
          ,s.srv_PRECIOTOTALITEM
          ,s.lty_CODIGOPERSONA
          ,s.lty_ORDTARJETABONUS
          ,s.lty_NUMTARJETABONUS
          ,s.lty_TIPOTARJETA
          ,s.lty_CODTIPOPERSONA
          ,s.lty_CODTIPOPERSONA_D
          ,s.lty_TIPODEDOCUMENTO
          ,s.lty_TIPODEDOCUMENTO_D
          ,s.lty_NRODOCUMENTO
          ,s.lty_NRORUC
          ,s.lty_NOMBRES
          ,s.lty_APELLIDOPATERNO
          ,s.lty_APELLIDOMATERNO
          ,s.lty_FECHANACIMIENTO
          ,s.lty_EDAD
          ,s.lty_EDAD_RANGO
          ,s.lty_SEXO_TIT_D
          ,s.lty_F_ESTADOCIVIL_D
          ,s.lty_F_COMPARTEDATOS_D
          ,s.lty_F_AUTCANJE_D
          ,s.lty_F_CLTEFALLECIDO_D
          ,s.lty_RAZONSOCIAL
          ,s.lty_CODPOS
          ,s.lty_DIRECCION
          ,s.lty_DEPARTAMENTO
          ,s.lty_PROVINCIA
          ,s.lty_DISTRITO
          ,s.lty_DISTRITO_ID
          ,s.lty_REFERENCIA
          ,s.lty_ESTADO
          ,s.lty_ESTADO_D
          ,s.lty_COORDENADAX
          ,s.lty_COORDENADAY
          ,s.lty_NSE
          ,s.lty_TELEFONO
          ,s.lty_TELEFONO_D
          ,s.lty_EMAIL
          ,s.lty_HIJ_AS
          ,s.lty_HIJ_OS
          ,s.lty_HIJ_NN
          ,CASE s.srv_RUCEMISOR
                WHEN '20416026948' THEN IIF(rc.SUBGAFO IS NULL,NULL,'Negocios Propios')
                WHEN '20507885391' THEN IIF(rc.SUBGAFO IS NULL,NULL,'Negocios Propios')
                WHEN '20514020907' THEN IIF(rc.SUBGAFO IS NULL,NULL,'Negocios Propios')
                WHEN '20553255881' THEN IIF(rc.SUBGAFO IS NULL,NULL,'Negocios Propios')
                ELSE IIF(rc.SUBGAFO IS NULL,NULL,'Locatarios')
           END AS com_TipoNegocio
          ,s.com_ContratoRE
          ,rc.DEN_CONTRATO            AS com_denContrato
          ,rc.VIGCONTRATO             AS com_VigContrato
          ,rc.NOMCOMERCIAL            AS com_NomComercial
          ,rc.OBJALQUILER             AS com_ObjAlquiler
          ,rc.GAFO                    AS com_Gafo
          ,rc.SUBGAFO                 AS com_SubGafo
      FROM ods.SRVLYTY s
           LEFT JOIN bds.RE_CONTRATOS rc
             ON s.srv_SOCIEDAD = rc.SOCIEDAD
            AND s.srv_RUCEMISOR = rc.NIF
            AND s.com_ContratoRE = rc.CONTRATO;

GO
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

  Call by:            none
  Affected table(s):  bds.SRVLYTY
  Used By:            BI
  Parameter(s):       none
  Log:                none
  Prerequisites:      proceso SRV (con columna contrato RE)
                      proceso LTY
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

    SELECT st.ID                                      AS    srv_ID
          ,st.NOMBRE                                  AS    srv_NOMBRE
          ,st.RAZONSOCIAL                             AS    srv_RAZONSOCIAL
          ,st.NOMBRETIENDA                            AS    srv_NOMBRETIENDA
          ,CONCAT(st.CODIGOMALL,'|',IIF(rc.GAFO IS NULL,'0',rc.GAFO),'|',IIF(rc.SUBGAFO IS NULL,'0',rc.SUBGAFO),'|',st.NOMBRETIENDA)  AS    srv_NOMBRETIENDA_ID
          ,st.CODIGOMALL                              AS    srv_CODIGOLOCACION --srv_CODIGOMALL
          ,lo.AZU_DESC_MED AS srv_CODIGOLOCACION_D --> reemplazo de (cl.DescripcionMall)
          ,st.CODIGOTIENDA                            AS    srv_CODIGOTIENDA
          ,st.RUCEMISOR                               AS    srv_RUCEMISOR
          --,st.IDENTIFICADORTERMINAL --> WA contrato RE
          ,st.NUMEROTERMINAL                          AS    srv_NUMEROTERMINAL
          ,st.SERIE                                   AS    srv_SERIE
          ,st.TIPOTRANSACCION                         AS    srv_TIPOTRANSACCION
          ,st.NUMEROTRANSACCION                       AS    srv_NUMEROTRANSACCION
          ,st.FECHA                                   AS    FECHA_ID --> uso como DIMENSION FECHA
          ,LEFT(st.HORA,8)                            AS    srv_HORA
          ,RIGHT(CONCAT('0',CAST(DATEPART(hh,st.HORA)    AS VARCHAR)),2)    AS srv_HORAHH
          ,RIGHT(CONCAT('0',CAST(DATEPART(mi,st.HORA)    AS VARCHAR)),2)    AS srv_HORAMI
          ,CASE    
               WHEN (DATEPART(hh,st.HORA)) < 8                  then  'R0.Madrugada (00-07)'
               WHEN (DATEPART(hh,st.HORA)) between   8  and  11 then  'R1.Mañana    (08-11)'
               WHEN (DATEPART(hh,st.HORA)) between  12  and  14 then  'R2.Almuerzo  (12-14)'
               WHEN (DATEPART(hh,st.HORA)) between  15  and  17 then  'R3.Tarde     (15-17)'
               WHEN (DATEPART(hh,st.HORA)) between  18  and  20 then  'R4.Cena      (18-20)'
               WHEN (DATEPART(hh,st.HORA)) between  21  and  23 then  'R5.Noche     (21-23)'
           END AS    srv_HORA_RANGO
          ,st.VENDEDOR                                AS    srv_VENDEDOR
          ,st.DNI                                     AS    srv_DNI
          ,st.RUC                                     AS    srv_RUC
          ,st.CE                                      AS    srv_CE
          ,st.DUIval                                  AS    srv_DUIval
          ,IIF(st.DNI IS NOT NULL,st.DNI,IIF(st.RUC IS NOT NULL,st.RUC,IIF(st.CE IS NOT NULL,st.CE,NULL))) AS  srv_DUI
          ,IIF(st.DNI IS NOT NULL,'DNI',IIF(st.RUC IS NOT NULL,'RUC',IIF(st.CE IS NOT NULL,'CE',NULL)))    AS  srv_DUITIPO
          ,st.NOMBRECLIENTE                           AS    srv_NOMBRECLIENTE
          ,st.DIRECCIONCLIENTE                        AS    srv_DIRECCIONCLIENTE
          ,st.BONUS                                   AS    srv_BONUS
          ,st.MONEDA                                  AS    srv_MONEDA
          ,st.MEDIOPAGO                               AS    srv_MEDIOPAGO
          ,st.TOTALVALORVENTABRUTA                    AS    srv_TOTVALORVTABRUTA
          ,st.DESCUENTOSGLOBAL                        AS    srv_DESCUENTOSGLOBAL
          ,st.MONTOTOTALIGV                           AS    srv_MONTOTOTALIGV
          ,st.TOTALVALORVENTANETA                     AS    srv_TOTVALORVENTANETA
          ,st.ORDENITEM                               AS    srv_ORDENITEM
          ,st.CANTIDADUNIDADESITEM                    AS    srv_CANTUNIDADESITEM
          ,st.CODIGOPRODUCTO                          AS    srv_CODIGOPRODUCTO
          ,st.DESCRIPCIONPRODUCTO                     AS    srv_DESCRIPCIONPROD
          ,st.PRECIOVENTAUNITARIOITEM                 AS    srv_PRECIOVTAUNITITEM
          ,st.CARGODESCUENTOITEM                      AS    srv_CARGODESCUENTOITEM
          ,st.PRECIOTOTALITEM                         AS    srv_PRECIOTOTALITEM
          ,lc.CODIGOPERSONA                           AS    lty_CODIGOPERSONA
          ,lc.ORDTARJETABONUS                         AS    lty_ORDTARJETABONUS
          ,lc.NUMTARJETABONUS                         AS    lty_NUMTARJETABONUS
          ,lc.TIPOTARJETA                             AS    lty_TIPOTARJETA
          ,lc.CODIGOTIPOPERSONA                       AS    lty_CODTIPOPERSONA
          ,lc.CODIGOTIPOPERSONA_D                     AS    lty_CODTIPOPERSONA_D
          ,lc.TIPODEDOCUMENTO                         AS    lty_TIPODEDOCUMENTO
          ,lc.TIPODEDOCUMENTO_D                       AS    lty_TIPODEDOCUMENTO_D
          ,lc.NRODOCUMENTO                            AS    lty_NRODOCUMENTO
          ,lc.NRORUC                                  AS    lty_NRORUC
          ,lc.NOMBRES                                 AS    lty_NOMBRES
          ,lc.APELLIDOPATERNO                         AS    lty_APELLIDOPATERNO
          ,lc.APELLIDOMATERNO                         AS    lty_APELLIDOMATERNO
          ,lc.FECHANACIMIENTO                         AS    lty_FECHANACIMIENTO
          ,lc.EDAD                                    AS    lty_EDAD
          ,lc.EDAD_RANGO                              AS    lty_EDAD_RANGO
          ,lc.SEXO_TIT_D                              AS    lty_SEXO_TIT_D
          ,lc.FLAGESTADOCIVIL_D                       AS    lty_F_ESTADOCIVIL_D
          ,lc.FLAGCOMPARTEDATOS_D                     AS    lty_F_COMPARTEDATOS_D
          ,lc.FLAGAUTCANJE_D                          AS    lty_F_AUTCANJE_D
          ,lc.FLAGCLTEFALLECIDO_D                     AS    lty_F_CLTEFALLECIDO_D
          ,lc.RAZONSOCIAL                             AS    lty_RAZONSOCIAL
          ,lc.CODPOS                                  AS    lty_CODPOS
          ,lc.DIRECCION                               AS    lty_DIRECCION
          ,lc.DEPARTAMENTO                            AS    lty_DEPARTAMENTO
          ,lc.PROVINCIA                               AS    lty_PROVINCIA
          ,lc.DISTRITO                                AS    lty_DISTRITO
          ,IIF(lc.CODIGOPERSONA IS NULL,NULL,CONCAT(lc.DEPARTAMENTO,'|',lc.PROVINCIA,'|',lc.DISTRITO)) AS    lty_DISTRITO_ID
          ,lc.REFERENCIA                              AS    lty_REFERENCIA
          ,lc.ESTADO                                  AS    lty_ESTADO
          ,lc.ESTADO_D                                AS    lty_ESTADO_D
          ,lc.COORDENADAX                             AS    lty_COORDENADAX
          ,lc.COORDENADAY                             AS    lty_COORDENADAY
          ,lc.NSE                                     AS    lty_NSE
          ,lc.TELEFONO                                AS    lty_TELEFONO
          ,IIF(lc.TELEFONO IS NULL, NULL, lc.TELEFONO_D) AS lty_TELEFONO_D
          ,lc.EMAIL                                   AS    lty_EMAIL
          ,lc.HIJ_AS                                  AS    lty_HIJ_AS
          ,lc.HIJ_OS                                  AS    lty_HIJ_OS
          ,lc.HIJ_NN                                  AS    lty_HIJ_NN
          ,CASE st.RUCEMISOR
                WHEN '20416026948' THEN IIF(rc.SUBGAFO IS NULL,NULL,'Negocios Propios')
                WHEN '20507885391' THEN IIF(rc.SUBGAFO IS NULL,NULL,'Negocios Propios')
                WHEN '20514020907' THEN IIF(rc.SUBGAFO IS NULL,NULL,'Negocios Propios')
                WHEN '20553255881' THEN IIF(rc.SUBGAFO IS NULL,NULL,'Negocios Propios')
                ELSE IIF(rc.SUBGAFO IS NULL,NULL,'Locatarios')
           END AS com_TipoNegocio
          ,rc.CONTRATO                AS com_ContratoRE --> st.IDENTIFICADORTERMINAL (WA contrato RE)
          ,rc.DEN_CONTRATO            AS com_denContrato
          ,rc.VIGCONTRATO             AS com_VigContrato
          ,rc.NOMCOMERCIAL            AS com_NomComercial
          ,rc.OBJALQUILER             AS com_ObjAlquiler
          ,rc.GAFO                    AS com_Gafo
          ,rc.SUBGAFO                 AS com_SubGafo
      INTO bds.SRVLYTY
      FROM bds.SRV_TABLON st
        LEFT JOIN ini.LYTY_ASOCIADO lo
          ON st.CODIGOMALL = lo.AZU_IDGRCO
        LEFT JOIN bds.LYTY_CLI lc
          ON st.DNI = lc.NRODOCUMENTO
        LEFT JOIN bds.RE_CONTRATOS rc
          ON lo.SAP_SOC = rc.SOCIEDAD
         AND st.RUCEMISOR = rc.NIF
         --AND st.IDENTIFICADORTERMINAL = rc.CONTRATO --> HABILITAR al remover --*temporal*

        --*temporal-----------------------------
        LEFT JOIN ods.SRVCOM_OPERADORES_temp so
          ON lo.AZU_IDGRCO = so.CODIGOMALL 
         AND rc.NIF = so.RUCEMISOR
         AND rc.CONTRATO = so.CONTRATO_RE
        --------------------------------temporal*
     WHERE rc.ORDINTERLOCCOMERCIAL = 1
GO
SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [ods].[sp_srvlty]
AS
  /***************************************************************************************************
  Procedure:          [ods].sp_srvlty
  Create Date:        20210521
  Author:             dÁlvarez
  Description:        consolida SRV y Loyalty
  Call by:            tbd
  Affected table(s):  ods.SRVLYTY
  Used By:            BI
  Parameter(s):       none
  Log:                none
  Prerequisites:      proceso SRV (con columna contrato RE)
                      proceso LTY
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
  --182s

    /*WA para columna con CONTRATO RE
    UPDATE bds.SRV_TABLON
       SET IDENTIFICADORTERMINAL = so.CONTRATO_RE
      FROM ods.SRVCOM_OPERADORES_temp so
           INNER JOIN bds.SRV_TABLON st
              ON so.CODIGOMALL = st.CODIGOMALL 
             AND so.RUCEMISOR = st.RUCEMISOR
             AND so.CODIGOTIENDA = st.CODIGOTIENDA;
    */

    TRUNCATE TABLE ods.SRVLYTY;

    DROP INDEX IX1_SRVLYTY ON ods.SRVLYTY;

    INSERT INTO ods.SRVLYTY
    SELECT st.ID                                      AS    srv_ID
          ,st.NOMBRE                                  AS    srv_NOMBRE
          ,st.RAZONSOCIAL                             AS    srv_RAZONSOCIAL
          ,st.NOMBRETIENDA                            AS    srv_NOMBRETIENDA
          ,lo.SAP_SOC                                 AS    srv_SOCIEDAD
          ,st.CODIGOMALL                              AS    srv_CODIGOLOCACION
          ,lo.AZU_DESC_MED                            AS    srv_CODIGOLOCACION_D
          ,st.CODIGOTIENDA                            AS    srv_CODIGOTIENDA
          ,st.RUCEMISOR                               AS    srv_RUCEMISOR
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
          ,st.IDENTIFICADORTERMINAL                AS com_ContratoRE --> (WA contrato RE)
      FROM bds.SRV_TABLON st
           LEFT JOIN ini.LYTY_ASOCIADO lo
             ON st.CODIGOMALL = lo.AZU_IDGRCO
           LEFT JOIN bds.LYTY_CLI lc
             ON st.DNI = lc.NRODOCUMENTO

    CREATE INDEX IX1_SRVLYTY ON ods.SRVLYTY(srv_SOCIEDAD, srv_RUCEMISOR, com_ContratoRE);

GO
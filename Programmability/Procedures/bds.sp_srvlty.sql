SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [bds].[sp_srvlty]
AS
  /***************************************************************************************************
  Procedure:          [bds].sp_srvlty
  Create Date:        20210521
  Author:             dÁlvarez
  Description:        todo el proceso de tablas LTY/SRV/SRVLTY
                      carga la tabla final (a ser ingestada por SAC).
                      posteriormente la tabla se exporta en CSV usando *> dbeaver <* con las sgtes caracteristicas:
                        delimiter: |
                        quote characters: "
                        quote always: string
                        null string: vacio
                        encoding: UTF-8

                      20210911: se debe exportar: bds.SRV_LYTY_dlt y guardar como SRV_LYTY.csv
                      **NOTA:: aquellos clientes con CODIGOPERSONA = '9999999999' provienen de un archivo plano externo

  Call by:            none
  Affected table(s):  bds.SRV_LYTY
  Used By:            BI
  Parameter(s):       none
  Log:                none
  Prerequisites:      proceso SRV
                      proceso LTY
  ****************************************************************************************************
  SUMMARY OF CHANGES
  Date(YYYYMMDD)      Author              Comments
  ------------------- ------------------- ------------------------------------------------------------
  20210521            dÁlvarez            creación
  20210601            dÁlvarez            se unifican dos SP como mejora (se renombra sp_srvlty_SAC)
  20210610            dÁlvarez            se adiciona lógica del delta (para cargar a SAC)
  20210713            dÁlvarez            MD_UNI
  
  ***************************************************************************************************/

    SELECT --TOP 100000
           st.ID                                      AS    srv_ID
          ,st.NOMBRE                                  AS    srv_NOMBRE
          ,st.RAZONSOCIAL                             AS    srv_RAZONSOCIAL
          ,st.NOMBRETIENDA                            AS    srv_NOMBRETIENDA
          ,CONCAT(st.CODIGOMALL,'|',IIF(sco.Gafo IS NULL,'0',sco.Gafo),'|',IIF(sco.SubGafo IS NULL,'0',sco.SubGafo),'|',st.NOMBRETIENDA)  AS    srv_NOMBRETIENDA_ID
          ,st.CODIGOMALL                              AS    srv_CODIGOLOCACION --srv_CODIGOMALL
          ,cl.DescripcionMall                         AS    srv_CODIGOLOCACION_D
          ,st.CODIGOTIENDA                            AS    srv_CODIGOTIENDA
          ,st.RUCEMISOR                               AS    srv_RUCEMISOR
          --,st.IDENTIFICADORTERMINAL                   AS    srv_IDENTIFICADORTERMINAL
          ,st.NUMEROTERMINAL                          AS    srv_NUMEROTERMINAL
          ,st.SERIE                                   AS    srv_SERIE
          ,st.TIPOTRANSACCION                         AS    srv_TIPOTRANSACCION
          ,st.NUMEROTRANSACCION                       AS    srv_NUMEROTRANSACCION
          ,st.FECHA                                   AS    FECHA_ID
          --,st.FECHA                                   AS    srv_FECHA --->>> cambio x DIMENSION FECHA
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
          --,st.CAJERO                                  AS    srv_CAJERO
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
          --,lc.SEXO_TIT                                AS    lty_SEXO_TIT
          ,lc.SEXO_TIT_D                              AS    lty_SEXO_TIT_D
          --,lc.FLAGESTADOCIVIL                         AS    lty_FLAGESTADOCIVIL
          ,lc.FLAGESTADOCIVIL_D                       AS    lty_F_ESTADOCIVIL_D
          --,lc.FLAGTIENEHIJOS                          AS    lty_FLAGTIENEHIJOS
          --,lc.FLAGTIENEHIJOS_D                        AS    lty_FLAGTIENEHIJOS_D
          --,lc.FLAGTIENETELEFONO                       AS    lty_FLAGTIENETELEFONO
          --,lc.FLAGTIENETELEFONO_D                     AS    lty_FLAGTIENETELEFONO_D
          --,lc.FLAGTIENECORREO                         AS    lty_FLAGTIENECORREO
          --,lc.FLAGTIENECORREO_D                       AS    lty_FLAGTIENECORREO_D
          --,lc.FLAGCOMPARTEDATOS                       AS    lty_FLAGCOMPARTEDATOS
          ,lc.FLAGCOMPARTEDATOS_D                     AS    lty_F_COMPARTEDATOS_D
          --,lc.FLAGAUTCANJE                            AS    lty_FLAGAUTCANJE
          ,lc.FLAGAUTCANJE_D                          AS    lty_F_AUTCANJE_D
          --,lc.FLAGCLTEFALLECIDO                       AS    lty_FLAGCLTEFALLECIDO
          ,lc.FLAGCLTEFALLECIDO_D                     AS    lty_F_CLTEFALLECIDO_D
          ,lc.RAZONSOCIAL                             AS    lty_RAZONSOCIAL
          --,lc.FECHACREACION_PER                       AS    lty_FECHACREACION_PER
          --,lc.HORACREACION_PER                        AS    lty_HORACREACION_PER
          --,lc.FECHAULTMODIF_PER                       AS    lty_FECHAULTMODIF_PER
          --,lc.FECHACARGAINICIAL_PER                   AS    lty_FECHACARGAINICIAL_PER
          --,lc.FECHACARGAULTMODIF_PER                  AS    lty_FECHACARGAULTMODIF_PER
          ,lc.CODPOS                                  AS    lty_CODPOS
          ,lc.DIRECCION                               AS    lty_DIRECCION
          ,lc.DEPARTAMENTO                            AS    lty_DEPARTAMENTO
          ,lc.PROVINCIA                               AS    lty_PROVINCIA
          ,lc.DISTRITO                                AS    lty_DISTRITO
          ,IIF(lc.CODIGOPERSONA IS NULL,NULL,CONCAT(lc.DEPARTAMENTO,'|',lc.PROVINCIA,'|',lc.DISTRITO)) AS    lty_DISTRITO_ID
          --,lc.FLAGULTIMO_DIR                          AS    lty_FLAGULTIMO_DIR
          ,lc.REFERENCIA                              AS    lty_REFERENCIA
          ,lc.ESTADO                                  AS    lty_ESTADO
          ,lc.ESTADO_D                                AS    lty_ESTADO_D
          ,lc.COORDENADAX                             AS    lty_COORDENADAX
          ,lc.COORDENADAY                             AS    lty_COORDENADAY
          --,lc.FLAGCOORDENADA                          AS    lty_FLAGCOORDENADA
          ,lc.NSE                                     AS    lty_NSE
          ,lc.TELEFONO                                AS    lty_TELEFONO
          --,lc.TELEFONO_D                              AS    lty_TELEFONO_D
          ,IIF(lc.TELEFONO IS NULL, NULL, lc.TELEFONO_D) AS lty_TELEFONO_D
          --,lc.FECHACREACION_TEL                       AS    lty_FECHACREACION_TEL
          ,lc.EMAIL                                   AS    lty_EMAIL
          --,lc.FECHACREACION_EML                       AS    lty_FECHACREACION_EML
          ,lc.HIJ_AS                                  AS    lty_HIJ_AS
          ,lc.HIJ_OS                                  AS    lty_HIJ_OS
          ,lc.HIJ_NN                                  AS    lty_HIJ_NN
          --,lc.HIJ_TOT                                 AS    lty_HIJ_TOT
          ,CASE st.RUCEMISOR
                WHEN '20416026948' THEN IIF(sco.SubGafo IS NULL,NULL,'Negocios Propios')
                WHEN '20507885391' THEN IIF(sco.SubGafo IS NULL,NULL,'Negocios Propios')
                WHEN '20514020907' THEN IIF(sco.SubGafo IS NULL,NULL,'Negocios Propios')
                WHEN '20553255881' THEN IIF(sco.SubGafo IS NULL,NULL,'Negocios Propios')
                ELSE IIF(sco.SubGafo IS NULL,NULL,'Locatarios')
           END AS com_TipoNegocio
          --,CONCAT(SUBSTRING(st.FECHA,1,4),SUBSTRING(st.FECHA,6,2),SUBSTRING(st.FECHA,9,2)) AS modFECHA
          --,SUBSTRING(st.FECHA,1,4)                  AS modANO
          --,SUBSTRING(st.FECHA,6,2)                  AS modMES
          --,CONCAT(SUBSTRING(st.FECHA,1,4),SUBSTRING(st.FECHA,6,2)) AS modPERIODO
          --,SUBSTRING(st.FECHA,9,2)                  AS modDIA
          --,DATENAME(MONTH,CAST(st.FECHA AS DATE))   AS modMES_NOM
          --,DATEPART(WEEK,CAST(st.FECHA AS DATE))    AS modSEMANA_NRO
          --,DATEPART(WEEKDAY,CAST(st.FECHA AS DATE)) AS modSEMANA_DIA
          --,CASE DATEPART(WEEKDAY,CAST(st.FECHA AS DATE))
          --      WHEN 1 THEN 'Lunes'
          --      WHEN 2 THEN 'Martes'
          --      WHEN 3 THEN 'Miércoles'
          --      WHEN 4 THEN 'Jueves'
          --      WHEN 5 THEN 'Viernes'
          --      WHEN 6 THEN 'Sábado' 
          --      WHEN 7 THEN 'Domingo' END AS modDIA_NOM
          --,CASE DATEPART(WEEKDAY,CAST(st.FECHA AS    DATE))
          --      WHEN 1 THEN 'L'
          --      WHEN 2 THEN 'M'
          --      WHEN 3 THEN 'X'
          --      WHEN 4 THEN 'J'
          --      WHEN 5 THEN 'V'
          --      WHEN 6 THEN 'S'
          --      WHEN 7 THEN 'D'END AS modDIA_NOM_I
          ,sco.CONTRATO_RE                            AS com_ContratoRE
          ,sco.VICNCN_denominacionContrato            AS com_denContrato
          ,sco.VigenciaContrato                       AS com_VigContrato
          ,sco.NombreComercial                        AS com_NomComercial
          ,sco.ObjetoAlquiler                         AS com_ObjAlquiler
          ,sco.Gafo                                   AS com_Gafo
          ,sco.SubGafo                                AS com_SubGafo
      INTO bds.SRVLYTY
      FROM bds.SRV_TABLON st
           LEFT JOIN bds.COM_LOCACIONES cl
                  ON st.CODIGOMALL = cl.CodigoLocacion
           LEFT JOIN bds.LYTY_CLI lc
                  ON st.DNI = lc.NRODOCUMENTO
           LEFT JOIN bds.SRVCOM_OPERADORES sco
                  ON sco.RUCEMISOR    = st.RUCEMISOR
                 AND sco.CODIGOMALL   = st.CODIGOMALL
                 AND sco.FECHA        = st.FECHA
                 AND sco.CODIGOTIENDA = st.CODIGOTIENDA

--  TRUNCATE TABLE bds.SRV_LYTY_tmp;
--
--  INSERT INTO bds.SRV_LYTY_tmp
--  SELECT * FROM bds.SRV_LYTY sl;
--
--  TRUNCATE TABLE bds.SRV_LYTY;
--
--  INSERT INTO bds.SRV_LYTY
--  SELECT st.ID                           AS srv_ID
--        ,st.NOMBRE                       AS srv_NOMBRE
--        ,st.RAZONSOCIAL                  AS srv_RAZONSOCIAL
--        ,st.NOMBRETIENDA                 AS srv_NOMBRETIENDA
--        ,st.CODIGOMALL                   AS srv_CODIGOMALL
--        ,st.CODIGOTIENDA                 AS srv_CODIGOTIENDA
--        ,st.RUCEMISOR                    AS srv_RUCEMISOR
--        ,st.IDENTIFICADORTERMINAL        AS srv_IDENTIFICADORTERMINAL
--        ,st.NUMEROTERMINAL               AS srv_NUMEROTERMINAL
--        ,st.SERIE                        AS srv_SERIE
--        ,st.TIPOTRANSACCION              AS srv_TIPOTRANSACCION
--        ,st.NUMEROTRANSACCION            AS srv_NUMEROTRANSACCION
--        ,st.FECHA                        AS srv_FECHA
--        ,st.HORA                         AS srv_HORA
--        ,st.CAJERO                       AS srv_CAJERO
--        ,st.VENDEDOR                     AS srv_VENDEDOR
--        ,st.DNI                          AS srv_DNI
--        ,st.RUC                          AS srv_RUC
--        ,ods.fn_validaDNI(st.DNI) AS srv_DNI_Valido
--        ,st.NOMBRECLIENTE                AS srv_NOMBRECLIENTE
--        ,st.DIRECCIONCLIENTE             AS srv_DIRECCIONCLIENTE
--        ,st.BONUS                        AS srv_BONUS
--        ,st.MONEDA                       AS srv_MONEDA
--        ,st.MEDIOPAGO                    AS srv_MEDIOPAGO
--        ,st.TOTALVALORVENTABRUTA         AS srv_TOTALVALORVENTABRUTA
--        ,st.DESCUENTOSGLOBAL             AS srv_DESCUENTOSGLOBAL
--        ,st.MONTOTOTALIGV                AS srv_MONTOTOTALIGV
--        ,st.TOTALVALORVENTANETA          AS srv_TOTALVALORVENTANETA
--        ,st.ORDENITEM                    AS srv_ORDENITEM
--        ,st.CANTIDADUNIDADESITEM         AS srv_CANTIDADUNIDADESITEM
--        ,st.CODIGOPRODUCTO               AS srv_CODIGOPRODUCTO
--        ,st.DESCRIPCIONPRODUCTO          AS srv_DESCRIPCIONPRODUCTO
--        ,st.PRECIOVENTAUNITARIOITEM      AS srv_PRECIOVENTAUNITARIOITEM
--        ,st.CARGODESCUENTOITEM           AS srv_CARGODESCUENTOITEM
--        ,st.PRECIOTOTALITEM              AS srv_PRECIOTOTALITEM
--        ,lc.CODIGOPERSONA                AS lty_CODIGOPERSONA
--        ,lc.ORDTARJETABONUS              AS lty_ORDTARJETABONUS
--        ,lc.NUMTARJETABONUS              AS lty_NUMTARJETABONUS
--        ,lc.TIPOTARJETA                  AS lty_TIPOTARJETA
--        ,lc.CODIGOTIPOPERSONA            AS lty_CODIGOTIPOPERSONA
--        ,lc.CODIGOTIPOPERSONA_D          AS lty_CODIGOTIPOPERSONA_D
--        ,lc.TIPODEDOCUMENTO              AS lty_TIPODEDOCUMENTO
--        ,lc.TIPODEDOCUMENTO_D            AS lty_TIPODEDOCUMENTO_D
--        ,lc.NRODOCUMENTO                 AS lty_NRODOCUMENTO
--        ,lc.NRORUC                       AS lty_NRORUC
--        ,lc.NOMBRES                      AS lty_NOMBRES
--        ,lc.APELLIDOPATERNO              AS lty_APELLIDOPATERNO
--        ,lc.APELLIDOMATERNO              AS lty_APELLIDOMATERNO
--        ,lc.FECHANACIMIENTO              AS lty_FECHANACIMIENTO
--        ,lc.EDAD                         AS lty_EDAD
--        ,lc.EDAD_RANGO                   AS lty_EDAD_RANGO
--        ,lc.SEXO_TIT                     AS lty_SEXO_TIT
--        ,lc.SEXO_TIT_D                   AS lty_SEXO_TIT_D
--        ,lc.FLAGESTADOCIVIL              AS lty_FLAGESTADOCIVIL
--        ,lc.FLAGESTADOCIVIL_D            AS lty_FLAGESTADOCIVIL_D
--        ,lc.FLAGTIENEHIJOS               AS lty_FLAGTIENEHIJOS
--        ,lc.FLAGTIENEHIJOS_D             AS lty_FLAGTIENEHIJOS_D
--        ,lc.FLAGTIENETELEFONO            AS lty_FLAGTIENETELEFONO
--        ,lc.FLAGTIENETELEFONO_D          AS lty_FLAGTIENETELEFONO_D
--        ,lc.FLAGTIENECORREO              AS lty_FLAGTIENECORREO
--        ,lc.FLAGTIENECORREO_D            AS lty_FLAGTIENECORREO_D
--        ,lc.FLAGCOMPARTEDATOS            AS lty_FLAGCOMPARTEDATOS
--        ,lc.FLAGCOMPARTEDATOS_D          AS lty_FLAGCOMPARTEDATOS_D
--        ,lc.FLAGAUTCANJE                 AS lty_FLAGAUTCANJE
--        ,lc.FLAGAUTCANJE_D               AS lty_FLAGAUTCANJE_D
--        ,lc.FLAGCLTEFALLECIDO            AS lty_FLAGCLTEFALLECIDO
--        ,lc.FLAGCLTEFALLECIDO_D          AS lty_FLAGCLTEFALLECIDO_D
--        ,lc.RAZONSOCIAL                  AS lty_RAZONSOCIAL
--        ,lc.FECHACREACION_PER            AS lty_FECHACREACION_PER
--        ,lc.HORACREACION_PER             AS lty_HORACREACION_PER
--        ,lc.FECHAULTMODIF_PER            AS lty_FECHAULTMODIF_PER
--        ,lc.FECHACARGAINICIAL_PER        AS lty_FECHACARGAINICIAL_PER
--        ,lc.FECHACARGAULTMODIF_PER       AS lty_FECHACARGAULTMODIF_PER
--        ,lc.CODPOS                       AS lty_CODPOS
--        ,lc.DIRECCION                    AS lty_DIRECCION
--        ,lc.DEPARTAMENTO                 AS lty_DEPARTAMENTO
--        ,lc.PROVINCIA                    AS lty_PROVINCIA
--        ,lc.DISTRITO                     AS lty_DISTRITO
--        ,lc.FLAGULTIMO_DIR               AS lty_FLAGULTIMO_DIR
--        ,lc.REFERENCIA                   AS lty_REFERENCIA
--        ,lc.ESTADO                       AS lty_ESTADO
--        ,lc.ESTADO_D                     AS lty_ESTADO_D
--        ,lc.COORDENADAX                  AS lty_COORDENADAX
--        ,lc.COORDENADAY                  AS lty_COORDENADAY
--        ,lc.FLAGCOORDENADA               AS lty_FLAGCOORDENADA
--        ,lc.NSE                          AS lty_NSE
--        ,lc.TELEFONO                     AS lty_TELEFONO
--        ,lc.TELEFONO_D                   AS lty_TELEFONO_D
--        ,lc.FECHACREACION_TEL            AS lty_FECHACREACION_TEL
--        ,lc.EMAIL                        AS lty_EMAIL
--        ,lc.FECHACREACION_EML            AS lty_FECHACREACION_EML
--        ,lc.HIJ_AS                       AS lty_HIJ_AS
--        ,lc.HIJ_OS                       AS lty_HIJ_OS
--        ,lc.HIJ_NN                       AS lty_HIJ_NN
--        ,lc.HIJ_TOT                      AS lty_HIJ_TOT
--  FROM bds.SRV_TABLON st LEFT JOIN bds.LYTY_CLI lc ON st.DNI = lc.NRODOCUMENTO;
--
--  --tabla bds.SRV_LYTY_dlt para enviar a SAC (renombrar SRV_LYTY.csv)
--  TRUNCATE TABLE bds.SRV_LYTY_dlt;
--
--  INSERT INTO bds.SRV_LYTY_dlt
--  SELECT * FROM bds.SRV_LYTY
--  EXCEPT
--  SELECT * FROM bds.SRV_LYTY_tmp;
--
----transacciones de los DNI del archivo plano
----WITH wrkard AS (SELECT DISTINCT srv_ID 
----                  FROM bds.SRV_LYTY
----                 WHERE lty_CODIGOPERSONA = '9999999999')
----INSERT INTO bds.SRV_LYTY_dlt
----SELECT sl.* 
----  FROM bds.SRV_LYTY sl INNER JOIN wrkard 
----    ON sl.srv_ID = wrkard.srv_ID;

GO
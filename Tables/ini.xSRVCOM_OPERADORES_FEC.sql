CREATE TABLE [ini].[xSRVCOM_OPERADORES_FEC] (
  [RUCEMISOR] [varchar](11) NULL,
  [CODIGOMALL] [varchar](2) NULL,
  [FECHA] [varchar](10) NULL,
  [CODIGOTIENDA] [varchar](4) NULL,
  [CONTRATO_RE] [varchar](10) NULL
)
ON [PRIMARY]
GO

EXEC sys.sp_addextendedproperty N'MS_Description', 'ESTA TABLA SERÁ REEMPLAZADA CON LA COLUMNA CONTRATORE DEL SRV', 'SCHEMA', N'ini', 'TABLE', N'xSRVCOM_OPERADORES_FEC'
GO
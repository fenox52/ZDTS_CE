*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZDTS_PALLETCODE.................................*
DATA:  BEGIN OF STATUS_ZDTS_PALLETCODE               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZDTS_PALLETCODE               .
CONTROLS: TCTRL_ZDTS_PALLETCODE
            TYPE TABLEVIEW USING SCREEN '9000'.
*.........table declarations:.................................*
TABLES: *ZDTS_PALLETCODE               .
TABLES: ZDTS_PALLETCODE                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .


library(odbc)
library(DBI)
library(dplyr)
library(dbplyr)
con <- dbConnect(odbc(),
              driver = 'SQL Server',
              server = 'iceman',
              database = 'KREG_EDW_DEV',
              trusted_connection=TRUE)

con <- dbConnect(odbc(),
              driver = 'SQL Server',
              server = 'iceman',
              database = 'KREG_EDW_DEV',
              trusted_connection=TRUE)
topofview <-  dbGetQuery(con,
"
select top 10 *
from [EDWDimensional].[v_SupplyChain_TurnsHistory_DataMart]
")
print(topofview)

# upsertR
upsertR is a simple R wrapper that supports *upserting* an R dataframe to a target SQL server. The package relies on the DBI package for handling connections and tables. 

# Installing upsertR
Install the package directly from github with devtools. Run the first line if you do not currently have devtools installed. 

```R
# install.packages('devtools') 
devtools::install_github('HenrikVarmer/upsertR')
```

# Functions 
There is only one core function in upsertR: ```upsert()```, which lets you upsert a dataframe to a target SQL server. The below example will upsert data ```df``` to SQL server connection ```con``` to target table ods.events.

```R
upsert(connection = con,    # SQL server connection string
       dataframe  = df,     # input dataframe
       schema     = ods,    # Target schema name on SQL server
       table      = events, # Target table name on SQL server
       delete     = TRUE)   # specifies whether to delete old ID's not present in input DF. TRUE deletes
```

# upsertR
upsertR is a simple R package that supports *upserting* an R dataframe to a target SQL server. The package relies on the DBI package for handling connections and tables. 

# Installing upsertR
Install the package directly from github with devtools. Run the first line if you do not currently have devtools installed. 

```R
# install.packages('devtools') 
devtools::install_github('HenrikVarmer/upsertR')
```

# Functions 
There is only one core function in upsertR: ```upsert()```, which lets you upsert a dataframe to a target SQL server. See below for an example. 

```R
upsert(con,    # SQL server connections string
       df,     # input dataframe
       schema, # Target schema name on SQL server
       table,  # Target table name on SQL server
       delete = TRUE) # specifies whether to delete old ID's not present in input DF. TRUE deletes old ID's
```

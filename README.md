# upsertR
upsertR is a simple R package that supports *upserting* an R dataframe to a target SQL server 

# Installing upsertR
Install the package directly from github with devtools. Run the first line if you do not currently have devtools installed.

```R
# install.packages('devtools') 
devtools::install_github('HenrikVarmer/upsertR')
```

# Functions 
There is only one core function in upsertR: upsert(), which lets you upsert a dataframe to a target SQL server. See below for an example. 


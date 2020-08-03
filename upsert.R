#' Updates table with "upsert" methodology.
#'
#' @param con ODBC connection.
#' @param df dataframe to use for update
#' @param schema Schema that table resides in e.g. "dbo"
#' @param table table name e.g. "events".
#' @param delete Specifies what to do if record is not in source, if TRUE then record is removed from target.
#' @return status code: 0 eq. no error, 1 if error during write.
#' @examples
#' updateTable(odscon, "dbo", "events")
upsert <- function(con, df, schema,table,delete=FALSE){
  
  tablename = paste(schema,table, sep = ".")
  
  table_id <- DBI::Id(
    schema  = schema,
    table    = paste(table,"temp",sep = "_")
  )
  
  DBI::dbWriteTable(
    conn        = con,
    name        = table_id,
    value       = df,
    overwrite   = T,
    append      = F
  )
  
  innerfn <- function(tab){
    return(paste0("select COLUMN_NAME from ",
                  "INFORMATION_SCHEMA.",
                  tab,
                  " where TABLE_NAME = '", table, "' and TABLE_SCHEMA = '", schema, "'"))
  }
  cmd <-innerfn("CONSTRAINT_COLUMN_USAGE")
  res <- dbSendQuery(con,cmd)
  keys <- dbFetch(res)$COLUMN_NAME
  dbClearResult(res)
  
  cmd <-innerfn("COLUMNS")
  
  res <- dbSendQuery(con,cmd)
  values <- dbFetch(res)$COLUMN_NAME
  dbClearResult(res)
  
  values <- setdiff(values,c(keys,"SysStart","SysEnd"))
  print(as.character(keys))
  print(values)
  delete_ <- ""
  if(delete) delete_ <- " When not matched BY SOURCE THEN DELETE"
  
  truncate <- paste0("TRUNCATE TABLE ",tablename,"_temp;")
  statement <- paste0(
    "MERGE INTO ", tablename, " as t",
    " Using ",
    tablename,"_temp", " as s",
    " on ", paste0(paste0("t.",keys, "=", "s.",keys ), collapse = " and "),
    " WHEN MATCHED THEN ",
    " UPDATE SET ",paste0(paste0("t.",values, "=", "s.",values ), collapse = ", "),
    " When not matched by target then ",
    " Insert (",paste0(c(keys,values),collapse = ","),")",
    " VALUES (",paste0(c(paste0("s.",keys),paste0("s.",values)),collapse = ","),")",
    delete_,";",
    truncate
  )
  dbExecute(con,statement)
  return(statement)
}

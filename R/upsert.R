#' Quote a SQL Server identifier
#'
#' Wraps an identifier in square brackets and escapes any embedded closing
#' bracket, following the T-SQL delimited identifier rules. This is a pure
#' helper used by [build_merge_statement()] so that the SQL string can be
#' constructed and tested without a live database connection.
#'
#' @param x Character vector of identifiers.
#' @return Character vector of bracket-quoted identifiers.
#' @keywords internal
#' @noRd
quote_identifier <- function(x) {
  paste0("[", gsub("]", "]]", x, fixed = TRUE), "]")
}

#' Build a T-SQL MERGE statement
#'
#' Constructs the `MERGE` statement used to upsert the staging (`*_temp`) table
#' into the target table. This function performs **no** database I/O, which
#' makes it straightforward to unit test.
#'
#' @param schema Schema that the target table resides in, e.g. `"dbo"`.
#' @param table Target table name, e.g. `"events"`. The staging table is
#'   assumed to be named `<table>_temp` in the same schema.
#' @param keys Character vector of key (matching) column names.
#' @param values Character vector of non-key column names to update/insert.
#' @param delete Logical. If `TRUE`, rows present in the target but absent from
#'   the source are deleted (`WHEN NOT MATCHED BY SOURCE THEN DELETE`).
#' @return A single character string containing the `MERGE` statement.
#' @export
#' @examples
#' build_merge_statement("dbo", "events", keys = "id",
#'                       values = c("name", "ts"), delete = TRUE)
build_merge_statement <- function(schema, table, keys, values, delete = FALSE) {
  if (length(keys) == 0L) {
    stop("`keys` must contain at least one column to match on.", call. = FALSE)
  }

  schema_q <- quote_identifier(schema)
  target   <- paste0(schema_q, ".", quote_identifier(table))
  source   <- paste0(schema_q, ".", quote_identifier(paste0(table, "_temp")))

  on_clause <- paste0(
    paste0("t.", quote_identifier(keys), " = s.", quote_identifier(keys)),
    collapse = " AND "
  )

  insert_cols <- paste0(quote_identifier(c(keys, values)), collapse = ", ")
  insert_vals <- paste0("s.", quote_identifier(c(keys, values)), collapse = ", ")

  clauses <- c(
    paste0("MERGE INTO ", target, " AS t"),
    paste0("USING ", source, " AS s"),
    paste0("ON ", on_clause)
  )

  if (length(values) > 0L) {
    update_set <- paste0(
      paste0("t.", quote_identifier(values), " = s.", quote_identifier(values)),
      collapse = ", "
    )
    clauses <- c(clauses, "WHEN MATCHED THEN UPDATE SET", update_set)
  }

  clauses <- c(
    clauses,
    "WHEN NOT MATCHED BY TARGET THEN",
    paste0("INSERT (", insert_cols, ")"),
    paste0("VALUES (", insert_vals, ")")
  )

  if (isTRUE(delete)) {
    clauses <- c(clauses, "WHEN NOT MATCHED BY SOURCE THEN DELETE")
  }

  paste0(paste(clauses, collapse = "\n"), ";")
}

#' Upsert a data frame into a SQL Server table
#'
#' Writes `df` to a staging table (`<table>_temp`), introspects the target
#' table's key and value columns from `INFORMATION_SCHEMA`, and executes a
#' T-SQL `MERGE` to upsert the staged rows into the target table. The write,
#' merge and truncate are wrapped in a single transaction so that a failure
#' does not leave a half-populated staging table behind.
#'
#' @param con A [DBI::DBIConnection-class] to a SQL Server database.
#' @param df Data frame to upsert into the target table.
#' @param schema Schema that the target table resides in, e.g. `"dbo"`.
#' @param table Target table name, e.g. `"events"`.
#' @param delete Logical. If `TRUE`, rows present in the target but absent from
#'   `df` are deleted. Defaults to `FALSE`.
#' @return Invisibly, the `MERGE` statement that was executed.
#' @importFrom DBI dbWriteTable dbGetQuery dbExecute dbQuoteString
#'   dbQuoteIdentifier dbBegin dbCommit dbRollback Id
#' @export
#' @examples
#' \dontrun{
#' con <- DBI::dbConnect(odbc::odbc(), "my-dsn")
#' upsert(con, df = events, schema = "dbo", table = "events", delete = TRUE)
#' }
upsert <- function(con, df, schema, table, delete = FALSE) {

  staging_id <- DBI::Id(schema = schema, table = paste0(table, "_temp"))

  introspect <- function(info_table) {
    sql <- paste0(
      "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.", info_table,
      " WHERE TABLE_NAME = ", DBI::dbQuoteString(con, table),
      " AND TABLE_SCHEMA = ", DBI::dbQuoteString(con, schema)
    )
    DBI::dbGetQuery(con, sql)$COLUMN_NAME
  }

  DBI::dbBegin(con)
  tryCatch(
    {
      DBI::dbWriteTable(
        conn      = con,
        name      = staging_id,
        value     = df,
        overwrite = TRUE,
        append    = FALSE
      )

      keys   <- introspect("CONSTRAINT_COLUMN_USAGE")
      values <- setdiff(introspect("COLUMNS"), c(keys, "SysStart", "SysEnd"))

      statement <- build_merge_statement(schema, table, keys, values, delete)

      DBI::dbExecute(con, statement)
      DBI::dbExecute(
        con,
        paste0("TRUNCATE TABLE ",
               DBI::dbQuoteIdentifier(con, staging_id), ";")
      )

      DBI::dbCommit(con)
      invisible(statement)
    },
    error = function(e) {
      DBI::dbRollback(con)
      stop(e)
    }
  )
}

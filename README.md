# upsertR

<!-- badges: start -->
[![R-CMD-check](https://github.com/HenrikVarmer/upsertR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/HenrikVarmer/upsertR/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)
<!-- badges: end -->

**upsertR** is a small R wrapper that *upserts* an R data frame into a target
SQL Server table using a single T-SQL `MERGE` statement. It relies on the
[DBI](https://dbi.r-dbi.org/) package for connections and table writes.

## How it works

`upsert()`:

1. Writes your data frame to a staging table named `<table>_temp`.
2. Introspects the target table's key and value columns from
   `INFORMATION_SCHEMA`.
3. Builds and executes a `MERGE` that updates matched rows, inserts new rows,
   and (optionally) deletes rows that are no longer present in the source.
4. Truncates the staging table.

The write, merge and truncate run inside a single transaction, so a failure
rolls back cleanly instead of leaving a half-populated staging table behind.

## Installation

Install directly from GitHub with **devtools** (or **remotes**). Run the first
line only if you do not already have devtools installed.

```r
# install.packages("devtools")
devtools::install_github("HenrikVarmer/upsertR")
```

## Usage

There is a single core function, `upsert()`. The example below upserts the data
frame `df` into the target table `ods.events` over the connection `con`.

```r
library(upsertR)

upsert(
  con    = con,      # a DBI connection to SQL Server
  df     = df,       # input data frame
  schema = "ods",    # target schema name
  table  = "events", # target table name
  delete = TRUE      # TRUE deletes target rows not present in df
)
```

### Building the MERGE without a database

The SQL builder is exposed as a pure function so you can inspect or test the
generated statement without a database connection:

```r
build_merge_statement(
  schema = "dbo",
  table  = "events",
  keys   = "id",
  values = c("name", "ts"),
  delete = TRUE
)
```

## Development

Run the unit tests (no database required) with:

```r
devtools::test()
```

## License

MIT © 2020 Henrik Varmer. See [LICENSE.md](LICENSE.md).

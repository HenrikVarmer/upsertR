test_that("build_merge_statement builds a complete MERGE without delete", {
  sql <- build_merge_statement(
    schema = "dbo",
    table  = "events",
    keys   = c("id"),
    values = c("name", "ts"),
    delete = FALSE
  )

  # Target and source tables are bracket-quoted.
  expect_match(sql, "MERGE INTO [dbo].[events] AS t", fixed = TRUE)
  expect_match(sql, "USING [dbo].[events_temp] AS s", fixed = TRUE)

  # ON clause joins on the key column.
  expect_match(sql, "ON t.[id] = s.[id]", fixed = TRUE)

  # UPDATE sets only the value columns.
  expect_match(sql, "WHEN MATCHED THEN UPDATE SET", fixed = TRUE)
  expect_match(sql, "t.[name] = s.[name], t.[ts] = s.[ts]", fixed = TRUE)

  # INSERT lists keys + values.
  expect_match(sql, "WHEN NOT MATCHED BY TARGET THEN", fixed = TRUE)
  expect_match(sql, "INSERT ([id], [name], [ts])", fixed = TRUE)
  expect_match(sql, "VALUES (s.[id], s.[name], s.[ts])", fixed = TRUE)

  # Without delete = TRUE there is no DELETE clause.
  expect_false(grepl("WHEN NOT MATCHED BY SOURCE", sql, fixed = TRUE))

  # Statement is terminated.
  expect_match(sql, ";$")
})

test_that("build_merge_statement adds a DELETE clause when delete = TRUE", {
  sql <- build_merge_statement(
    schema = "dbo",
    table  = "events",
    keys   = c("id"),
    values = c("name"),
    delete = TRUE
  )

  expect_match(sql, "WHEN NOT MATCHED BY SOURCE THEN DELETE", fixed = TRUE)
})

test_that("build_merge_statement supports composite keys", {
  sql <- build_merge_statement(
    schema = "ods",
    table  = "sales",
    keys   = c("region", "year"),
    values = c("amount"),
    delete = FALSE
  )

  expect_match(sql, "ON t.[region] = s.[region] AND t.[year] = s.[year]",
               fixed = TRUE)
  expect_match(sql, "INSERT ([region], [year], [amount])", fixed = TRUE)
})

test_that("build_merge_statement omits UPDATE when there are no value columns", {
  sql <- build_merge_statement(
    schema = "dbo",
    table  = "keys_only",
    keys   = c("id"),
    values = character(0),
    delete = FALSE
  )

  expect_false(grepl("WHEN MATCHED THEN", sql, fixed = TRUE))
  expect_match(sql, "INSERT ([id])", fixed = TRUE)
  expect_match(sql, "VALUES (s.[id])", fixed = TRUE)
})

test_that("build_merge_statement errors when no keys are supplied", {
  expect_error(
    build_merge_statement("dbo", "events", keys = character(0),
                          values = c("name")),
    "at least one column"
  )
})

test_that("build_merge_statement escapes embedded closing brackets", {
  sql <- build_merge_statement(
    schema = "dbo",
    table  = "wei]rd",
    keys   = c("i]d"),
    values = c("v"),
    delete = FALSE
  )

  expect_match(sql, "[wei]]rd]", fixed = TRUE)
  expect_match(sql, "t.[i]]d] = s.[i]]d]", fixed = TRUE)
})

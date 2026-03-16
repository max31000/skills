---
name: sql-helper
description: >
  SQL and database operations. Use when the user works with SQL queries,
  database schema, migrations, or mentions "SQL", "query", "database",
  "migration", "schema", "index", "stored procedure", "PostgreSQL",
  "MSSQL", "MySQL", "Entity Framework", "EF Core".
---

# SQL & Database Helper

Assist with writing, optimizing, and debugging SQL and database operations.

## Query Writing
- Always use parameterized queries — never string concatenation.
- Prefer explicit column lists over SELECT *.
- Use CTEs for readability over deeply nested subqueries.
- Add table aliases for any query with joins.

## Performance Optimization
- Check execution plans (EXPLAIN / SET STATISTICS IO ON).
- Look for: table scans, missing indexes, implicit conversions, N+1 queries.
- Index strategy: cover the WHERE, JOIN, and ORDER BY columns.
- Avoid functions on indexed columns in WHERE (breaks index usage).
- For pagination: use keyset (WHERE id > @lastId) over OFFSET/FETCH for large datasets.

## EF Core / .NET Specific
- Use `.AsNoTracking()` for read-only queries.
- Avoid `.ToList()` before filtering — let the DB do the work.
- Use `IQueryable` projections (`.Select()`) to fetch only needed columns.
- Beware of lazy loading N+1 — use `.Include()` or split queries.
- Migrations: always review generated SQL before applying.

## Schema Design
- Use appropriate data types (do not store dates as strings).
- Add NOT NULL constraints by default, allow NULL only when semantically required.
- Foreign keys for referential integrity.
- Consider soft deletes (IsDeleted flag) vs hard deletes based on domain.

## Common Anti-patterns
- SELECT * in production code
- Missing indexes on foreign keys
- Using LIKE with leading wildcard (kills index)
- Storing comma-separated values instead of proper relations
- Not handling NULL in comparisons (NULL != NULL)

# Layoffs Data Cleaning in SQL (MySQL)

A practice project. I followed Alex the Analyst's SQL tutorial on a public layoffs dataset and worked through the cleaning steps myself in MySQL. This repo has my script and my notes on the choices it makes.

## Data

- One table, `layoffs`, with one row per layoff event: company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions.
- Covers 2020 to 2023.
- Source: [add the link to where you downloaded it].
- The raw table is never changed. The script copies it into staging tables and cleans the copy.

## What the script does

1. **Staging tables.** Copies `layoffs` into `layoffs_staging`, then into `layoffs_staging2`, so the raw data stays untouched.
2. **Duplicates.** Numbers each row with `ROW_NUMBER()` over all nine columns inside a CTE. MySQL won't delete from a CTE, so the numbered rows go into `layoffs_staging2` (with a `row_num` column) and the rows where `row_num > 1` are deleted there. I checked one flagged company (Casper) before deleting.
3. **Standardising text.**
   - Trimmed spaces from company names.
   - Merged the different spellings of Crypto in `industry` into one.
   - Removed a trailing full stop from "United States." in `country`.
   - Fixed two city names that had broken characters (Düsseldorf and Florianópolis).
4. **Dates.** The date column was imported as text. I converted it with `STR_TO_DATE(..., '%m/%d/%Y')`, then changed the column type to `DATE`.
5. **Blanks and nulls.**
   - Turned blank `industry` values into NULL.
   - Filled missing industries from another row for the same company, using a self-join.
   - Deleted rows where both `total_laid_off` and `percentage_laid_off` are NULL.
6. **Tidy up.** Dropped the `row_num` helper column.

## Row counts

Fill these in by running the queries on your own data.

| Stage | Rows |
|---|---|
| Raw table (`layoffs`) | [  ] |
| After removing duplicates | [  ] |
| After deleting rows with no layoff figures | [  ] |

```sql
SELECT COUNT(*) FROM layoffs;
SELECT COUNT(*) FROM layoffs_staging2;
```

Run the second query once after the duplicate step and once at the end. Number of industry values filled from other rows: [  ].

## Choices I made, and what they cost

- **Deleting rows with no layoff figures.** These rows have nothing to analyse, so I removed them. The cost is that those companies drop out of every total. If the aim were to keep a full record, I'd flag these rows instead of deleting them.
- **Duplicates need all nine columns to match.** Two rows with the same company and date but a different stage or funding figure are kept, because they might be separate events.
- **Filling industry from other rows** assumes a company has one industry. A company with a single row and no industry stays NULL.

## SQL used

Staging tables, `ROW_NUMBER()` with a CTE, `TRIM`, `UPDATE` with `LIKE`, `STR_TO_DATE`, `ALTER TABLE ... MODIFY`, self-join `UPDATE`, `DELETE`.

## How to run

1. Use MySQL 8 or later. The script uses window functions.
2. Import the raw data into a table called `layoffs`.
3. Run `data_cleaning.sql` from top to bottom. It changes `layoffs_staging2` in place, so reload the staging tables if you want to run it again.

## Files

- `data_cleaning.sql`: the cleaning script

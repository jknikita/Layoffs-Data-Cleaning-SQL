# Layoffs Data Cleaning using MySQL

A SQL data cleaning project that takes a raw global layoffs dataset and turns it into an analysis-ready table. All work is done in MySQL using a staging-table approach, so the raw data is never modified.

## Project Overview

The raw layoffs data contains duplicates, inconsistent labels, text-formatted dates, and missing values. This project cleans it step by step so it can support exploratory analysis or dashboards.

**Goal:** produce a clean, consistent table with reliable dates, categories and no duplicate or empty records.

## Tools & Skills Demonstrated

- **MySQL** (MySQL Workbench)
- Data cleaning and standardization
- CTEs and window functions (`ROW_NUMBER() OVER (PARTITION BY ...)`)
- Self-joins to fill missing values
- String functions (`TRIM`, `LIKE`) and date conversion (`STR_TO_DATE`)
- `ALTER TABLE`, `UPDATE`, `DELETE`, `CREATE TABLE ... LIKE`

## Dataset

- **Contents:** company, location, industry, total laid off, percentage laid off, date, funding stage, country and funds raised (in millions).
- **Source:** Layoffs dataset.

## Cleaning Steps

| # | Step | What was done |
|---|------|---------------|
| 1 | **Create staging table** | Copied the raw `layoffs` table into `layoffs_staging` so the original stays untouched. |
| 2 | **Remove duplicates** | Used `ROW_NUMBER()` partitioned across all columns. Because MySQL cannot delete from a CTE, the numbered rows were loaded into `layoffs_staging2` and rows with `row_num > 1` were deleted. |
| 3 | **Standardize data** | Trimmed whitespace in `company`, merged `Crypto` variants in `industry`, removed the trailing period from `United States.`, and fixed corrupted characters in `location` (Düsseldorf, Florianópolis). |
| 4 | **Convert date** | Converted `date` from text (`m/d/Y`) to a proper `DATE` type using `STR_TO_DATE`. |
| 5 | **Handle NULL and blank values** | Converted blank `industry` values to `NULL`, then filled them by self-joining on `company` where another record had the industry. |
| 6 | **Remove unnecessary data** | Deleted rows where both `total_laid_off` and `percentage_laid_off` were `NULL`, and dropped the helper `row_num` column. |

## Key Techniques

**Removing duplicates with a window function**

```sql
SELECT *,
ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off,
                 percentage_laid_off, `date`, stage, country,
                 funds_raised_millions
) AS row_num
FROM layoffs_staging;
```

**Filling missing values with a self-join**

```sql
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;
```


## Results

- Duplicate records removed.
- Inconsistent industry, country and location values standardized.
- `date` is a true `DATE` column, ready for time-based analysis.
- Missing industries filled where another record of the same company provided the value.
- Rows with no layoff information removed.



## Author

**Nikita Maria Johnson**
[LinkedIn](https://www.linkedin.com/) | [GitHub](https://github.com/)

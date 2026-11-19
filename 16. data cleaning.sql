-- Layoffs Data Cleaning
USE world_layoffs;

-- Preview the raw data
select *
from layoffs;

-- Create Staging Table
-- Work on a copy so the raw data stays intact
CREATE TABLE layoffs_staging
LIKE layoffs;

-- insert all the data of layoffs table into layoffs_staging
insert layoffs_staging
select *
from layoffs;

-- REMOVE DUPLICATES

-- Preview duplicates
WITH duplicate_cte AS
(
select *,
ROW_NUMBER() OVER(
PARTITION BY company, location,
 industry, total_laid_off, percentage_laid_off, `date`, 
 stage, country, funds_raised_millions) AS row_num
from layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;



-- MySQL cannot delete from a CTE, so row numbers are stored in a second staging table and the extra rows are deleted from there.

-- Create second staging table same structure plus row_nume
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Populate with row numbers
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location,
 industry, total_laid_off, percentage_laid_off, `date`, 
 stage, country, funds_raised_millions) AS row_num
from layoffs_staging;

-- REMOVED DUPLICATES WHERE ROW_NUM>1
DELETE
FROM layoffs_staging2
WHERE row_num > 1;


-- STANDARDIZE DATA

-- Company: remove leading and trailing whitespace
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Industry: merge variants of 'Crypto' into one label
select DISTINCT industry
from layoffs_staging2
ORDER BY industry;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Country: remove trailing period ('United States.'->'United States')
select distinct country
from layoffs_staging2
order by country;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Location: fix corrupted special characters
select distinct location
from layoffs_staging2
ORDER BY location;

UPDATE layoffs_staging2
SET location = 'Düsseldorf'
WHERE location LIKE '%sseldorf';

UPDATE layoffs_staging2
SET location = 'Florianópolis'
WHERE location LIKE 'Florian%polis';


-- CONVERT DATE COLUMN FROM TEXT TO DATE 
-- Common STR_TO_DATE format codes:
# %Y - 4 digit year(2026), %y - 2 digit year(26) 
# %m - month as numeric value, %M- month name
# %b - abbreviated month name, %d - day of the month
# %H hour in 24 hour format, %h - in 12 hour format
# %i minutes, %s-seconds,%p - AM or PM

-- Preview the conversion before applying it
select `date`,
str_to_date(`date`, '%m/%d/%Y')
from layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y');

-- Only run on the staging table, never on the raw table
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- HANDLE NULL AND BLANK VALUES

-- Convert blank industry values to NULL so they are handles consistently
UPDATE layoffs_staging2
SET industry = null
WHERE industry = '';

-- Preview companies with a missing inudstry
SELECT *
FROM layoffs_staging2
where industry is null;

-- Preview rows that can be filled from another record of the same company
-- Airbnb as one row with industry 'Travel' and one with NULL
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry is null OR t1.industry = '')
and t2.industry is not null;

-- Fill missing industry using a self join on company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry is null 
and t2.industry is not null;


-- REMOVE UNNECESSARY ROWS AND COLUMNS
-- Rows with neither total_laid_off nor percentage_laid_off carry no layoff information and cannot be used for analysis.
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


# remove row_num column
ALTER TABLE layoffs_staging2
drop column row_num;

-- FINAL CLEANED TABLE
SELECT *
FROM layoffs_staging2;

-- Row counts: raw vs cleaned
SELECT
    (SELECT COUNT(*) FROM layoffs)          AS raw_rows,
    (SELECT COUNT(*) FROM layoffs_staging2) AS cleaned_rows;

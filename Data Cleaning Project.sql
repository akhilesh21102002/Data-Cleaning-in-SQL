-- Data Cleaning

SELECT *
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values / Blank Values
-- 4. Remove Any Columns


CREATE TABLE layoffs_staging			#Creating a duplicate table for the raw data
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging					#Inserting data into the new table
SELECT *
FROM layoffs;



SELECT *,						#Creating a row_num column to check for duplicates
row_number() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

WITH duplicate_CTE as				#Creating a CTE for storing duplicate values
(
SELECT *,
row_number() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage
, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)

SELECT *					#Selecting everything which has a row_num greater than 1
FROM duplicate_CTE
WHERE row_num > 1;



CREATE TABLE `layoffs_staging2` (					#Creating a second new table to store data
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

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2					#Inserting the CTE query to the second new table
SELECT *,
row_number() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage
, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

DELETE								#Deleting duplicate entries from the dataset
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2;


-- Standardizing data -- Finding Issues in the data and fixing it

SELECT company, TRIM(company)			#Trimming white space in the company name
FROM layoffs_staging2;

UPDATE layoffs_staging2					#Updating the column data for company
SET company = TRIM(company);


SELECT DISTINCT industry				#Checking to see if same industry is written in different ways
FROM layoffs_staging2
ORDER BY 1;

SELECT *				#Checking which industries start with Crypto & something else
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)		#Trying to Trim the period from the US name. A little advanced code for doing that.
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2							#Updating the country column
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT `date`,
str_to_date(`date`, '%m/%d/%Y')					#Changing from string to Date
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y');


ALTER TABLE	layoffs_staging2							#Only do this on the staging table, never on the raw dataset table. We are changing the datatype of something
MODIFY COLUMN `date` DATE;

SELECT *
FROM layoffs_staging2;


-- 3. Working with Null/Blank Values


SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;			#Fairly useless when both are nulls

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';


SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = '';

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT *						#Self join the same table to see if there is any null/blank values in any of them. Look at the update from blanks to null statement above to figure this part out.
FROM layoffs_staging2 as t1
JOIN layoffs_staging2 as t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')					#Query for null/blank values
AND t2.industry IS NOT NULL;									#Query for not null values


UPDATE layoffs_staging2 as t1								#Updating the table records
JOIN layoffs_staging2 as t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL			
AND t2.industry IS NOT NULL;


SELECT *
FROM layoffs_staging2
WHERE company LIKE 'BALLY%';

SELECT *
FROM layoffs_staging2;


SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE								#Deleting columns where the values are null
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2				#Dropping columns from the dataset
DROP COLUMN row_num;		
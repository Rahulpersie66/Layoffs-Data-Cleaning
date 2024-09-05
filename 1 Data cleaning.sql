-- Data cleaning
-- it is basically where you get it in a MORE USABLE FORMST and FIX SOEM ISSUES in RAW data and when you start using data 
-- for visulaization or start using it in the project.

-- we r going to create a database -> then we are going to import a dataset from GITHUB
-- FIRST: we are going to create a SCHEMA by clicking on database in tab --> give schema name `world_layoff`
-- SECOND: download dataset.csv layoffs.csv from GITHUB
-- Third: RIGHT CLICK on tables under `world_layoff` schema you created
-- FOURTH : choose options `Table data import csv` -->add browse file and then next
-- create a new table -> chhose checkbox (DROP TABLE if exists)
-- NOTE MYSQL is gonna assigns autmoatically data type  so in our case date coulmn is assigned as text because of formtting of date type , but lets LEAVE it 
-- this way only, assuming we are GOING to IMPORT RAW data

-- FIFTH: NEXT-> next -> import data loading screen- >total records imported -> FINISH
-- SIXTH : now lest see the data we are going to working on : SELECT * from layoffs

SELECT *
FROM layoffs;

-- EDA: EXPLOARTORY DATA ANALYSIS
-- we are going to find trend, pattern and all these other things that is called Exploratory DATA analysis(EDA)

-- Data cleaning steps:
-- Step1:Remove duplicates
-- Step2: Standarize the input data (ISSUES with data that is spelling or thing slike that, where data format or spell is not same it should be)
-- Step3: Null and blank values: Look at null nad blank values ( try to poulate them if needed)
-- NOTE: there are cases where you should not poulate them WHEN DATESET IS LARGE try to avoid poulate them or some USEACSE when null or blank have significane in table
-- Step4: remove any columns or Rows: There are instances ytou can remove columns or rows when that is IRRELEVANT to ETL processes 
-- NOTE: When working with MASSIVE datasets here are columns tha are completely IRRELEVANT or BLANK ou don't have any ETL processes that is required for it, then you can
-- for get rid of it
-- BUT Oftentimes DATA is AUTOMATICALLY loaded into DATSETS or TABLES then REMOVING a column is BIG BIG NO
-- So SOLUTION:----
-- CREATE a new TABLE STAGGING table for `layoffs` to save the RAW TABLE data

-- creating RAW table EASY
CREATE TABLE layoffs_stagging
LIKE layoffs;
-- AFTER this we have LAYOFF strutucre to LAYOFF_STAGING 

SELECT *
FROM layoffs_stagging;

-- SO now we have to INSERT data into this table by using INSERT commands
INSERT layoffs_stagging
SELECT * FROM layoffs;
-- THIS Statement can insert `layoffs` data into `layoffs_stagging` directly

-- WHY be created STAGGING table?
-- becasue we gonna change the stagging table alot if we made a MISTAKE we want to SAVE OUR RAW data from that MISTAKE.
-- and iTS also a GOOD practice to craete a STAGGING data first then to work on RAW data , because human can make mistake on RAW data 

-- Step1: remove duplicate, if no `unique identifier` i.e id us given so we can find duplicate using ROW_NUMBER() OVER (partition every column)
-- and also sometimes try on some of the columns if by HIT AND TRIAL we found some duplicates using some columns in ROW_NUMBER()
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_stagging;

-- now to check duoplicate check for --> row_num > 1 i.e 2 or 3 will be duplicate i.e duplicate entry
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_stagging;
-- WHERE row_num directly will not work, so have to save it in CTE
-- save the table in CTE to use row_num or subquery

WITH duplicate_Cte AS (
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_stagging

)
SELECT *
FROM duplicate_Cte
WHERE row_num > 1;

-- to confirm if that is duplicate ..lets look at example of one company for e.g from above `Oda` has row_num >1
SELECT * FROM layoffs_stagging
WHERE company ='Oda';

-- we found `Oda` entries are not really dupliacte ..actually it was diffrent because we didnot used every column for partition BY 
-- So when we use it for partitionby every column..we get REAL DUPLICATE
WITH duplicate_Cte AS (
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,stage, country, funds_raised_millions) AS row_num
FROM layoffs_stagging

)
SELECT *
FROM duplicate_Cte
WHERE row_num > 1;

-- now agin check if these are real duplicates --> by taking one company e..g
SELECT * FROM layoffs_stagging
WHERE company ='Casper';

-- In Microsoft SQL Server , PostGre it is EASIER to delete the duplicate rows just by using CTE `row_num` = 2 and delete them from query as we are able to identify row_num in CTEquery aboveand delte them from actual table
-- BUT In case of SEQUEL it is lot more tricker 


-- e.g Microsoft delete for DUPLICATES
WITH duplicate_Cte AS (
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,stage, country, funds_raised_millions) AS row_num
FROM layoffs_stagging

)
DELETE
FROM duplicate_Cte
WHERE row_num > 1;
-- it will not work in Sequel or mysql

-- SO SOLUTION  for this in MySql is :: creating ANOTHER STAGGING table and then delete according to row_num > 1

-- 1st way to create table
CREATE TABLE layoffs_stagging2 
WITH duplicate_Cte AS (
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,stage, country, funds_raised_millions) AS row_num
FROM layoffs_stagging

)
SELECT *
FROM duplicate_Cte;

-- to check if ALL row are there
SELECT CoUNT(*) FROM layoffs_stagging2;
DROp TAbLE layoffs_stagging2;

-- second WAY is to RIGHT CLICK ON `layoffs_stagging` -> click option copy to clipboard -> then create statement -> paste it on editor --> 
-- dding one column `row_num` an its data type INT
CREATE TABLE `layoffs_stagging2` (
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

-- now check if created or not
SELECT * FROM layoffs_stagging2;
-- now we have empty table

-- NOW we want to insert into TABLE values fromCTE expression
INSERT INTO layoffs_stagging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,stage, country, funds_raised_millions) AS row_num
FROM layoffs_stagging;

-- now check if ist working
SELECT COUNT(*) from layoffs_stagging2;

-- BEFORE Deleting chek with SLEECT staemnt if RIGHT output is deleteing or NOT
SELECT *
FROM layoffs_stagging2
WHERE row_num > 1; -- to check for duplicate

DELETE 
FROM layoffs_stagging2
WHERE row_num > 1;

-- now check if delete or not
SELECT * from layoffs_stagging2; -- can  check by counting rows or checking for duplicate again

-- It is so much easier if you have UNIQUE column .. os much easier to delete


-- Step-2::: Standarizing the data
-- check for ezch column single by single
-- lets take first column `comapny` and display it using distinct --- and notice the difference in both so we can STANDARIZE the output
SELECT DISTINCT(company), company FROM layoffs_stagging2;
-- So little bit of TRimming is required
SELECT DISTINCT(TRIM(company)),company FROM layoffs_stagging2;
-- Distinct comes after SELECT as first column

-- now update the data according to it-- JUST write UPDATE command for  atble
-- UPDATE tablename SET col_name = new_col_property
UPDATE layoffs_stagging2
SET company = TRIM(company);

-- now check for next column
SELECT DISTINCT(industry), industry FROM layoffs_stagging2 ORDER by 1;
-- HERE`Crypto` , `Crypto Currency` and `CryptoCurrency` all are same SO STANDARIZE them --> by giving them same name

-- before updating -- show the data that you want to update
SELECT (industry) FROM layoffs_stagging2 
WHERE industry LIKE 'Crypto%';

-- now update and show the dat aas above select query
UPDATE layoffs_stagging2 
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
-- select the data as the field name `Crypto` AS most of the field is Crypto (like 90%) field are Crypto and rest 10% are Cryptocurrence or Crypto Currencey
SELECT DISTINCT(industry), industry FROM layoffs_stagging2 ORDER by 1;
-- after updating if data is STANDARIZE as `Crypto` for most of the column then its GOOD that Update is worikng
-- we WILL DEAL with empty and NUll strings LATER


-- Now check for next column -- location
SELECT DISTINCT(location), location FROM layoffs_stagging2 ORDER BY 1;
-- loaction looks GOOD, so leave it 


-- Now checks for COUNTRY
SELECT Distinct(Country), Country FROM layoffs_stagging2 ORDER BY 1;

-- Here `United States` country error as 'United States' and 'United States.' is present so make them STANDARZIE output
-- Before Updating just SHOW sleect query which values you are uypdating
SELECT DISTINCT(COuntry), country FROM layoffs_stagging2
WHERE country LIKE 'United States%';

-- to remove single charcter i.e (`.`,`,`,`'`, we can USE TARILING function)
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) FROM layoffs_stagging2
WHERE country LIKE 'United States%';
-- Little advance technique to remove '.' from country

-- now UPDATE the command data
UPDATE layoffs_stagging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';


-- now CHECK if data is updated or not
SELECT DISTINCT(COuntry), country FROM layoffs_stagging2
WHERE country LIKE 'United States%';

-- IMPORTANT things
-- If you are USING TIME SERIES for VISUALIZATION or EDA(Exploratory DATA analysis) later, this `date column` type need to be changed from `txt`
-- to `date`
-- we can use `STR_TO_DATE('date_column_name', `%m/%d/%Y`)--- it takes two parameter --FIRST one-- COLUMN_NAME and SECOND-- format of date
-- i.e STRING date is in our database and it convert that ..STORED date in %m/%d/%Y to ---> YYYY-MM-DD format
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_stagging2;
-- Y for 4 letter YEAR and y for FIRST two letter from STRING date in DB
-- We converted `type text` into 'dateTime` of the column so we can do EDA(exploratory data analysiss or visualization)

-- UPDATE date column first in date format using --> STR_TO_DATE(`date`, '%m/%d/%Y)
UPDATE layoffs_stagging2
SET date = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Shows the display the upated data and then 
SELECT `date` FROM layoffs_stagging2;

-- DESCribe table -- to se ethat `date column` is still `text` type
DESC layoffs_stagging2;

-- so we have to change its type to `dateTime` for VIUSALIZATION and EDA purpose
-- EARLIER while LOADING the data into LAYOFFS we COULD have DO IT, but ISSUE is THAT, it WILL GIVE ERROR at THAT time BECAUSE OF FORMAT
--  at THAT time is DIFFERENT 08/19/2024 to `2024-09-19` (this is Date format)
-- USE ALTER satement-- ALTER TABLE table_name
-- e.g MODIFY COLUMN col_name DATE---> where DATE is TYPE
ALTER TABLE  layoffs_stagging2
MODIFY COLUMN `date` DATE;

-- NOW again CHECK if TYPE Is cahnged or not
DESC layoffs_stagging2;


-- STEP 3: We want to CHECK for nUL and EMPTY "" values and have to think what to DO  WITH that
SELECT * FROM layoffs_stagging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;
-- two NULLcolumns are petty useless so we have to think to poulate this data

-- ANOTHER issue when there were `industry column` taht was having "" or null value, we have to think about how to POPULATE IT
SELECT * FROM layoffs_stagging2
WHERE industry IS NULL OR industry = "";
-- SO THINK how we can poulate this thing by using logic for NULL, or empty values

-- Lets search for AIrbnb s it is present for the "" and NULL industry so maybe its company `Airbnb` is present in other rows so we can 
-- populate from there
SELECT * FROM layoffs_stagging2
WHERE company = 'Airbnb'; 
-- So here Airbnb company have industry as `travel` and one as `empty` so we can oulate the data for empty "" field
-- iT is superuseful to populate the data that can be populated

-- if some entries have `MULTIPLE layoff`, we can  POPULATE Those entries
-- By  JOIN sam etable on basis of company and location is same and where t1.is NULL and t2 is NOT NULL
SELECT *
FROM layoffs_stagging2 t1
JOIN layoffs_stagging2 t2
	ON t1.company = t2.company AND t1.location=t2.location
    WHERE (t1.industry IS NULL OR t1.industry ="")
    AND t2.industry IS NOT NULL;
    
-- now for better understanding only see company --> industry for t1 and t2
SELECT t1.company,t1.industry, t2.company,t2.industry
FROM layoffs_stagging2 t1
JOIN layoffs_stagging2 t2
	ON t1.company = t2.company AND t1.location=t2.location
    WHERE (t1.industry IS NULL OR t1.industry ="")
    AND (t2.industry IS NOT NULL AND  t2.industry !="");

-- So if t1.industry is blank we gonna popukate it with t2.industry
-- SO UPDATE statement for it
UPDATE layoffs_stagging2 t1
JOIN layoffs_stagging2 t2
	ON t1.company = t2.company
SET t1.industry=t2.industry
    WHERE (t1.industry IS NULL OR t1.industry ="")
    AND (t2.industry IS NOT NULL AND  t2.industry !="");


-- Afterupdating pLEASE check with select statementif RIGHT thing updated or NOT
SELECT * FROM layoffs_stagging2
WHERE industry IS NULL OR industry = "";
-- its still showing industry coilumn EMPTY then there might be issue with QUERY or UPDATE didnot happened then THINK why this didnot worked
-- SO SOLUTION IS:
-- set all blank of the `industry` to NULL first then set them to `industry name` later iwth update query
-- UPDATE stagg2
-- SET industry = NULL 
-- WHERE industry =""
-- It will change every industry that is "" to NULL for standarize purpose.
-- So we can poulate the empty spacces easily


-- ANd now we can run the UPDATE query of JOIN to Populate the empty field 
-- UPDATE layoffs_stagging2 t1
-- JOIN layoffs_stagging2 t2
-- 	ON t1.company = t2.company
-- SET t1.industry=t2.industry
--     WHERE t1.industry IS NULL 
--     AND (t2.industry IS NOT NULL );
-- AS there are now NO "" so we are only checking FOR NULL TO REPLACE with other values. to populate it

-- Now lest look AIRbnb query
SELECT * FROM layoffs_stagging2
WHERE company = 'Airbnb'; 
-- Now its populated

-- nbow check for NULL and "" in industry again
SELECT * FROM layoffs_stagging2
WHERE industry IS NULL OR industry = "";

-- since Bally's is still there lets look about this
SELECT * FROM layoffs_stagging2
WHERE company LIKE 'Bally%'; 
-- So there is oNLY 1 ROW for BALLYS, so we CANNOT populate it.


-- So percentage_laid_off, we have if TOTAL_employee given, then we can find %_laid_off that if TOTAL is this and this much were laid_off then % laid off is this
-- SAME for total_laid_off, if total employee were this and that %of that was laid off, then total_laid_off = %_laid_off*total_person
-- And for funds__raised_off we can COLLECT from WEB data


-- STEP4: Remove unwantd column and rows
SELECT * 
FROM layoffs_stagging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
-- THIS query will give us data THA GIVE NO INFO. about how many laid off and what percenatge is laid off
-- May be this data give us information about LOACTIONof company and fund_raised_off by company


-- SO if you are 100% SURE then ONLY DELETE the data.
-- should we DLEETE it I AM IFFY here.. but in next EXLORATORY dat analysis we dont need it
-- SO DONOT DELETE UNTIL YOU ARE 100% SURE

DELETE 
FROM layoffs_stagging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
-- now chek too if rows are deleted or NOT

-- show the output after delete ..to check if DELETED correctly
SELECT * 
FROM layoffs_stagging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * FROM layoffs_stagging2;


-- NOW WE have to DROP the column `row_num` that was used for DUPLICATION removal in starting 
-- SO DROP Column ROW_NUm
-- ALTER table `table_name` 
-- DROP COLUMN  `column_name`
ALTER TABLE layoffs_stagging2
DROP COLUMN row_num;

-- and check by dispalyimg SELECT
SELECT * FROM layoffs_stagging2;


-- After this CLEAN DATA we are gonna do EXPLOARTORY DATA ANALYSIS(EDA) on this CLEAN data.
-- and FINDING TREND, PATTERN and running COMPLEX QUERIES
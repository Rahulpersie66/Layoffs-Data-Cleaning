# Layoffs-Data-Cleaning
This repository provides a detailed guide for cleaning and preparing layoffs data for analysis. It includes instructions for importing, cleaning, and transforming data to make it suitable for Exploratory Data Analysis (EDA). Follow the steps to standardize, handle missing values, and ensure data accuracy for effective visualization and insights.


### README: Data Cleaning and Exploratory Data Analysis (EDA)


#### Step-by-Step Instructions

1. **Create a Schema and Import Dataset**
   - Create a new schema named `world_layoff` in your database.
   - Download the `layoffs.csv` file from GitHub.
   - Import the dataset into a table within the `world_layoff` schema:
     - Right-click on the `tables` section of the schema.
     - Choose `Table Data Import Wizard`, browse for the CSV file, and proceed.
     - Select the option to create a new table and ensure that the `DROP TABLE IF EXISTS` checkbox is checked.
     - Proceed with the import. MySQL will automatically assign data types, which may not be ideal (e.g., dates might be imported as text).

2. **Create a Staging Table**
   - Create a staging table `layoffs_stagging` to preserve the raw data:
     ```sql
     CREATE TABLE layoffs_stagging LIKE layoffs;
     ```
   - Insert data into the staging table:
     ```sql
     INSERT INTO layoffs_stagging
     SELECT * FROM layoffs;
     ```

3. **Remove Duplicates**
   - Use a Common Table Expression (CTE) to identify duplicates:
     ```sql
     WITH duplicate_Cte AS (
       SELECT *,
       ROW_NUMBER() OVER(
         PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
       ) AS row_num
       FROM layoffs_stagging
     )
     SELECT * FROM duplicate_Cte
     WHERE row_num > 1;
     ```
   - Create a new staging table for duplicates:
     ```sql
     CREATE TABLE layoffs_stagging2 AS
     WITH duplicate_Cte AS (
       SELECT *,
       ROW_NUMBER() OVER(
         PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
       ) AS row_num
       FROM layoffs_stagging
     )
     SELECT * FROM duplicate_Cte;
     ```
   - Delete duplicate rows:
     ```sql
     DELETE FROM layoffs_stagging2
     WHERE row_num > 1;
     ```

4. **Standardize Data**
   - Clean and standardize each column:
     - For `company` column:
       ```sql
       UPDATE layoffs_stagging2
       SET company = TRIM(company);
       ```
     - For `industry` column:
       ```sql
       UPDATE layoffs_stagging2
       SET industry = 'Crypto'
       WHERE industry LIKE 'Crypto%';
       ```
     - For `country` column:
       ```sql
       UPDATE layoffs_stagging2
       SET country = TRIM(TRAILING '.' FROM country)
       WHERE country LIKE 'United States%';
       ```

5. **Convert Date Column**
   - Convert the `date` column to the `DATE` type for analysis:
     ```sql
     UPDATE layoffs_stagging2
     SET date = STR_TO_DATE(date, '%m/%d/%Y');
     ALTER TABLE layoffs_stagging2
     MODIFY COLUMN date DATE;
     ```

6. **Handle Null and Empty Values**
   - Identify and populate NULL or empty values:
     ```sql
     SELECT * FROM layoffs_stagging2
     WHERE industry IS NULL OR industry = "";
     ```
   - Use JOIN operations to populate missing values:
     ```sql
     UPDATE layoffs_stagging2 t1
     JOIN layoffs_stagging2 t2
     ON t1.company = t2.company
     SET t1.industry = t2.industry
     WHERE (t1.industry IS NULL OR t1.industry = "")
     AND (t2.industry IS NOT NULL AND t2.industry != "");
     ```

7. **Remove Unwanted Columns and Rows**
   - Remove columns or rows that are irrelevant or contain no useful information:
     ```sql
     DELETE FROM layoffs_stagging2
     WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;
     ```
   - Drop temporary columns used for processing:
     ```sql
     ALTER TABLE layoffs_stagging2
     DROP COLUMN row_num;
     ```

8. **Final Verification**
   - Verify the final cleaned data to ensure that all necessary cleaning and transformations are correctly applied:
     ```sql
     SELECT * FROM layoffs_stagging2;
     ```

---

#### Next Steps: Exploratory Data Analysis (EDA)

With the cleaned dataset, you can now proceed with Exploratory Data Analysis (EDA) to uncover trends, patterns, and insights. This involves:

- Analyzing the distribution of layoffs across companies and locations.
- Investigating the impact of industry and company size on layoffs.
- Visualizing trends over time to identify any significant patterns or anomalies.

---

By following these steps, you ensure that your data is clean, standardized, and ready for in-depth analysis. Proper data cleaning is crucial for accurate and meaningful insights.

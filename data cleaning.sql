-- Data Cleaning

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null values or blank valueslayoffs_staging2layoffs_staging2
-- 4. Remove Any Columns 

-- Duplicate to Avoid Permanent Data Loss, Easy Rollback, Testing Changes...
create table layoffs_staging
like layoffs;

insert layoffs_staging
select *
from layoffs;

-- 1. Remove Duplicates

-- We can see that there are Duplicates in raw data.
with duplicate_cte as
(
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging
)
select *
from duplicate_cte
where row_num > 1;

-- We can't delete in CTEs
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` bigint DEFAULT NULL,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- row-partition part means if the params are same, it refers to duplicates.
insert into layoffs_staging2
select *,
row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging;

SET SQL_SAFE_UPDATES = 0;

delete
from layoffs_staging2
where row_num > 1;

-- 2. Standardize the Data

-- We can see that there are spaces before/after some companies names.
select company, (trim(company))
from layoffs_staging2
;

update layoffs_staging2
set company = trim(company)
;

-- we can see that in industry field, Crypto/CryptoCurrency/Crypto Currency refer to the same thing. 
select distinct(industry)
from layoffs_staging2
order by 1
;

-- most of them are 'Crypto'
select *
from layoffs_staging2
where industry like 'Crypto%';

update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';

-- look at location
select distinct location
from layoffs_staging2
order by 1;

-- look at country
select distinct country
from layoffs_staging2
order by 1;

-- or
select distinct country, trim(trailing '.' from country)
from layoffs_staging2
order by 1;

update layoffs_staging2
set country = 'United States'
where country like 'United States%';

-- look at date. if %y will only select first 2 (e.g. 20)
select `date`,
str_to_date(`date`, '%m/%d/%Y')
from layoffs_staging2
;

update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y')
;

alter table layoffs_staging2
modify column `date` Date;

-- 3. Null values or blank values

select *
from layoffs_staging2
where industry is null or industry = ''
;

select *
from layoffs_staging2
where company = 'Airbnb'
;

select *
from layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
    and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and t2.industry is not null
;

update layoffs_staging2
set industry = null
where industry = '';

update layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry is null
and t2.industry is not null
;

select *
from layoffs_staging2
where company like 'Bally%'
;
-- we can't populate any null data

-- 4. Remove Any Columns 

select *
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

-- Be confident to delete
delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

alter table layoffs_staging2
drop column row_num;

select *
from layoffs_staging2
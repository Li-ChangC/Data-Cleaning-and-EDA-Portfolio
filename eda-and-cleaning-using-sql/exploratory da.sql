-- Exploratory Data Analysis

select *
from layoffs_staging2
;

select YEAR(`date`), sum(total_laid_off)
from layoffs_staging2
group by YEAR(`date`)
order by 1 desc;

select company, sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc;

-- Large companies have the largest sum of laidoffs (Post-IPO)
select stage, sum(total_laid_off)
from layoffs_staging2
group by stage
order by 2 desc;

-- Rolling sum of total laid off
with Rolling_Total as
(
select substring(`date`, 1, 7) as `month`, sum(total_laid_off) as total_off
from layoffs_staging2
where substring(`date`, 1, 7) is not null
group by `month`
order by 1 asc
)
select `month`, total_off, sum(total_off) over(order by `month`) as rolling_total
from Rolling_Total
;

with Company_Year (company, years, total_laid_off) as
(
select company, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, year(`date`)
),
Company_Year_Rank as
(
select *, dense_rank() over (partition by years order by total_laid_off desc) as ranking
from Company_Year
where years is not null
)
select *
from Company_Year_Rank
where ranking <= 5
;
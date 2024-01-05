select *
from CovidProject..['covid and death]
order by 3,4

--select *
--from CovidProject..['covid and vaccinations]
--order by 3,4  --先按照第三列排序，如果第三列一致，就按照第四列排序，默认升序

select location, date, total_cases, new_cases, total_deaths, population
from CovidProject..['covid and death]
order by 1,2

--Looking at Total Cases vs Total Deaths
--shows likelihood of dying if you contract covid in your country

select Location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
from CovidProject..['covid and death]
where location like '%china%'
order by 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
select Location, date, total_cases, Population, ROUND((total_cases/Population)*100, 9) as PercentPopulationInfected
from CovidProject..['covid and death]
--where location like '%American%'
order by 1,2

--Looking at Countries with Highest Infextion Rate compared to Polulation
SELECT
Location, 
Population, 
MAX(total_cases) as HighestInfectionCountry, 
MAX((total_cases/population))*100 as PercentPopulationInfected
FROM
CovidProject..['covid and death]
GROUP BY  --定义需要聚合计算的组，比如所有相同的location和population聚集为一个组求其max,如果不定义的话可能导致SQL不清楚是要针对什么分组计算。
Location, 
Population
ORDER BY
PercentPopulationInfected desc

--Showing Countries with Highest Death Count per Population
SELECT
Location, 
MAX(total_deaths) as HighestDeathsCountry,
MAX((total_deaths/population))*100 as PercentPopulationDeaths
FROM
CovidProject..['covid and death]
WHERE  --以上方式容易出现混入一些非国家的大陆，比如Asia, Africa,所以要用where进行筛选
continent is not null
GROUP BY  --定义需要聚合计算的组，比如所有相同的location和population聚集为一个组求其max,如果不定义的话可能导致SQL不清楚是要针对什么分组计算。
Location
ORDER BY
PercentPopulationDeaths desc

--LET'S BREAK THINGS DOWN BY CONTINENT
--Showing continents with the highest death count per population
SELECT
continent, 
MAX(total_deaths) as HighestDeathsContinent,
MAX((total_deaths/population))*100 as PercentContinentDeaths
FROM
CovidProject..['covid and death]
WHERE
continent is not null
GROUP BY  --定义需要聚合计算的组，比如所有相同的location和population聚集为一个组求其max,如果不定义的话可能导致SQL不清楚是要针对什么分组计算。
continent
ORDER BY
PercentContinentDeaths desc

--GLOBAL NUMBERS
 SELECT
 date,
 SUM(cast(new_cases as int)) as DailyNew_cases,
 SUM(cast(new_deaths as int)) as DailyNew_deaths,
 CASE 
        WHEN SUM(cast(new_cases as int)) > 0 THEN SUM(cast(new_deaths as int)) * 100.0 / SUM(cast(new_cases as int))
        ELSE NULL -- 或者可以选择一个替代值如 0、-1 等表示无法计算或不适用
 END as DeathPercentage
FROM
CovidProject..['covid and death]
WHERE
continent is not null
GROUP BY
date
ORDER BY
1,2

--TOTAL NUMBER
select
SUM(new_cases) as total_cases,
SUM(new_deaths) as total_deaths,
CASE 
        WHEN SUM(cast(new_cases as int)) > 0 THEN SUM(cast(new_deaths as int)) * 100.0 / SUM(cast(new_cases as int))
        ELSE NULL -- 或者可以选择一个替代值如 0、-1 等表示无法计算或不适用
 END as DeathPercentage
from CovidProject..['covid and death]



--Looking at Total Population vs Vaccinations
SELECT
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) over   (PARTITION BY dea.Location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated, --虽然这个地方定义了RollingPeopleVaccinated,但是仍然不能直接在同一个selet中的下一排中直接使用
(SUM(vac.new_vaccinations) over (PARTITION BY dea.Location ORDER BY dea.location, dea.date)/dea.population )*100 as PercentageVaccinated
FROM 
CovidProject..['covid and death] dea
join
CovidProject..['covid and vaccinations] vac
on
dea.location = vac.location
and
dea.date = vac.date
WHERE
dea.continent is not null
ORDER by
2,3


--USE CTE（和上面一样的效果，只是更清晰高效）

With PopVsVac 
(
continent, 
location, 
date, 
population,  
new_vaccinations,
Rollingpeoplevaccinated
) --这堆括号里的内容可以有也可以没有
as
(
SELECT
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) over   (PARTITION BY dea.Location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM 
CovidProject..['covid and death] dea
join
CovidProject..['covid and vaccinations] vac
on
dea.location = vac.location
and
dea.date = vac.date
WHERE
dea.continent is not null
)
select *, 
(RollingPeopleVaccinated/Population) * 100 as PercentageVaccinated  --重新起一个select,这样Rollingpeoplevaccinated就可以直接使用了 
FROM PopVsVac

--TEMP TABLE(和上面一样的效果，另外一种方式，通过创建一个表格来实现)
DROP Table if exists
CREATE TABLE  #PercentPopulationVaccinated    --#后面的内容是本地临时表的名称。
(
Continent nvarchar(225),
Location nvarchar(225),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated   --必须在insert into后面跟一个本地临时表的名称。
SELECT
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) over   (PARTITION BY dea.Location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM 
CovidProject..['covid and death] dea
join
CovidProject..['covid and vaccinations] vac
on
dea.location = vac.location
and
dea.date = vac.date
WHERE
dea.continent is not null

SELECT *,(RollingPeopleVaccinated/Population) * 100 as PercentageVaccinated
FROM #PercentPopulationVaccinated

--Creating view to store data for later visualizations --这个视图是被永久的创建了的，和上面那个不一样。上面那个加#的是本地临时表，是临时的。
CREATE View PercentPopulationVaccinated as
SELECT
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) over (PARTITION BY dea.Location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM 
CovidProject..['covid and death] dea
join
CovidProject..['covid and vaccinations] vac
on
dea.location = vac.location
and
dea.date = vac.date
WHERE
dea.continent is not null

SELECT * FROM PercentPopulationVaccinated   --如果左边的数据库的view中不显示这个视图则用这个方式调用以便证明上面那个创建view的代码创建成功
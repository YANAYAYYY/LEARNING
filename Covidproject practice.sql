select *
from CovidProject..['covid and death]
order by 3,4

--select *
--from CovidProject..['covid and vaccinations]
--order by 3,4  --�Ȱ��յ������������������һ�£��Ͱ��յ���������Ĭ������

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
GROUP BY  --������Ҫ�ۺϼ�����飬����������ͬ��location��population�ۼ�Ϊһ��������max,���������Ļ����ܵ���SQL�������Ҫ���ʲô������㡣
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
WHERE  --���Ϸ�ʽ���׳��ֻ���һЩ�ǹ��ҵĴ�½������Asia, Africa,����Ҫ��where����ɸѡ
continent is not null
GROUP BY  --������Ҫ�ۺϼ�����飬����������ͬ��location��population�ۼ�Ϊһ��������max,���������Ļ����ܵ���SQL�������Ҫ���ʲô������㡣
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
GROUP BY  --������Ҫ�ۺϼ�����飬����������ͬ��location��population�ۼ�Ϊһ��������max,���������Ļ����ܵ���SQL�������Ҫ���ʲô������㡣
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
        ELSE NULL -- ���߿���ѡ��һ�����ֵ�� 0��-1 �ȱ�ʾ�޷����������
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
        ELSE NULL -- ���߿���ѡ��һ�����ֵ�� 0��-1 �ȱ�ʾ�޷����������
 END as DeathPercentage
from CovidProject..['covid and death]



--Looking at Total Population vs Vaccinations
SELECT
dea.continent,
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) over   (PARTITION BY dea.Location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated, --��Ȼ����ط�������RollingPeopleVaccinated,������Ȼ����ֱ����ͬһ��selet�е���һ����ֱ��ʹ��
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


--USE CTE��������һ����Ч����ֻ�Ǹ�������Ч��

With PopVsVac 
(
continent, 
location, 
date, 
population,  
new_vaccinations,
Rollingpeoplevaccinated
) --�������������ݿ�����Ҳ����û��
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
(RollingPeopleVaccinated/Population) * 100 as PercentageVaccinated  --������һ��select,����Rollingpeoplevaccinated�Ϳ���ֱ��ʹ���� 
FROM PopVsVac

--TEMP TABLE(������һ����Ч��������һ�ַ�ʽ��ͨ������һ�������ʵ��)
DROP Table if exists
CREATE TABLE  #PercentPopulationVaccinated    --#����������Ǳ�����ʱ������ơ�
(
Continent nvarchar(225),
Location nvarchar(225),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated   --������insert into�����һ��������ʱ������ơ�
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

--Creating view to store data for later visualizations --�����ͼ�Ǳ����õĴ����˵ģ��������Ǹ���һ���������Ǹ���#���Ǳ�����ʱ������ʱ�ġ�
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

SELECT * FROM PercentPopulationVaccinated   --�����ߵ����ݿ��view�в���ʾ�����ͼ���������ʽ�����Ա�֤�������Ǹ�����view�Ĵ��봴���ɹ�
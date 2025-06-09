select location, date, total_cases,new_cases,total_deaths, population
from covid_deaths
order by 1,2
--looking for total cases vs total deaths;

select location, date, total_cases,total_deaths,
(total_deaths/total_cases)*100 as DeadRate
from covid_deaths
Where location like 'Hungary'
order by 1,2

--looking at total cases vs population
--shows what percentage of population got covid

select location, date,population, total_cases,population,
(total_cases/population)*100 as DeadRate
from covid_deaths
Where location like 'Hungary'
order by 1,2

--looking at countries wih Highest Infection Rate compared to Population

select location,population,MAX(total_cases) as HighestInfectionCount,
MAX((total_cases/population))*100 as PercecntOfPopulationInfected
from covid_deaths
--Where location like 'Hungary'
Group by location, population
order by PercecntOfPopulationInfected desc

-- Showing coutries with highest dead count per population

select location, MAX (total_deaths) as totaldeadcount
--Where location like 'Hungary'
from covid_deaths
where continent is not null
and total_deaths is not null
Group by location
order by totaldeadcount desc

-- Let's Break things down by continent
select location, MAX (total_deaths) as totaldeadcount
--Where location like 'Hungary'
from covid_deaths
where continent is null
and total_deaths is not null
Group by location
order by totaldeadcount desc;

-- showing the continent with the highest dead count

select continent, MAX (total_deaths) as totaldeadcount
--Where location like 'Hungary'
from covid_deaths
where continent is not null
and total_deaths is not null
Group by continent
order by totaldeadcount desc

-- Global Numbers

select date, sum(new_cases) as totalcases, sum(new_deaths) as totaldeaths,sum(new_deaths)/Sum(new_cases)*100 as DeathsPercentage
from covid_deaths
--Where location like 'Hungary'
where continent is not null
group by date
order by 1,2


-- looking at Total Population vs Vaccination
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
Sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVacctinated,
--(RollingPeopleVacctinated/dea.population)
from covid_deaths dea
join covid_testing_vaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	order by 2,3
-- CTE
with PopvsVac(Continent,Location,Date,Population, New_Vaccinations, RollingPeopleVaccinated) as
(
select dea.continent,
dea.location,dea.date,
dea.population,
vac.new_vaccinations,
Sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVacctinated

--(RollingPeopleVacctinated/dea.population)
from covid_deaths dea
join covid_testing_vaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
--	order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)* 100
From PopvsVac ;

WITH PopvsVac AS (
    SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.location, dea.date
        ) AS RollingPeopleVaccinated
        --, (RollingPeopleVaccinated / dea.population) AS VaccinationRate
    FROM 
        covid_deaths dea
    JOIN 
        covid_testing_vaccination vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)
SELECT *
FROM PopvsVac;


--temp table
CREATE TEMP TABLE PercentPopulationVaccinated (
    Continent TEXT,
    Location TEXT,
    Date DATE,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.date
    ) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_testing_vaccination vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, 
       (RollingPeopleVaccinated * 100.0 / NULLIF(Population, 0)) AS PercentVaccinated
FROM PercentPopulationVaccinated;


-- creating view to store data for later visualisations

Create View PercentPopulationVaccinated as
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.location, dea.date
    ) AS RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_testing_vaccination vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--order by 1,2

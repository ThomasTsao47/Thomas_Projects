/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 3,4

-- Select Data that we are going to be starting with
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you get covid in your country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%' and 
		continent is not null 
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where continent is not null 
--Where location like '%states%'
order by 1,2

-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where continent is not null 
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

-- at which time Countries with the Highest Infection 
SELECT a.Location, a.date, a.Population, a.total_cases
  FROM PortfolioProject..CovidDeaths AS a
  JOIN (
	SELECT Location, Population, MAX(total_cases) as HighestInfectionCount
	  FROM PortfolioProject..CovidDeaths
	 WHERE continent is not null
	 GROUP BY Location, Population
		) AS b ON (
				a.location = b.location AND
				a.population = b.population AND
				a.total_cases = b.HighestInfectionCount)
 WHERE continent is not null;

-- Countries with Highest Total Death Count
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount   -- �n���ഫ Total_deaths ����ƫ��A
From PortfolioProject..CovidDeaths
Where continent is not null 
--Where location like '%states%'
Group by Location
order by TotalDeathCount desc;

-- Showing contintents with the highest death count per population
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
Group By date
order by 1

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
		,SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY vac.location ORDER BY vac.date) AS RollingPeopleVaccinated   --�Q�� PARTITOIN BY
	  --, (RollingPeopleVaccinated/dea.population)*100   -- �W�@��Ъ� RollingPeopleVaccinated �S��k�o�˪������ӥΡA�]���b�U�@�q�{���X�� CTE �B�z
  FROM PortfolioProject..CovidDeaths AS dea
  JOIN PortfolioProject..CovidVaccinations AS vac
	  ON dea.location = vac.location AND
		 dea.date = vac.date
 WHERE (dea.continent is not null) AND (vac.continent is not null)
 ORDER BY 2,3
 
-- Using CTE to perform Calculation on Partition By in previous query
 WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS   -- �ϥ�CTE���`�N�G�o��A���̪����ƶq�ݻP AS �᭱�����ƶq�@�P
 (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
			,SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY vac.location ORDER BY vac.date) AS RollingPeopleVaccinated 
	  FROM PortfolioProject..CovidDeaths AS dea
	  JOIN PortfolioProject..CovidVaccinations AS vac
		  ON dea.location = vac.location AND
			 dea.date = vac.date
	 WHERE (dea.continent is not null) AND (vac.continent is not null)
	 --ORDER BY 2,3
 )
 SELECT *, (RollingPeopleVaccinated/Population)*100   -- �ϥ�CTE���`�N�GWITH AS �᭱�n���o�ӡA���M����|�����~
   FROM PopvsVac;

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255), 
	Date datetime, 
	Population float, 
	New_Vaccinations float, 
	RollingPeopleVaccinated float
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
		,SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY vac.location ORDER BY vac.date) AS RollingPeopleVaccinated   --�Q�� PARTITOIN BY
	  --, (RollingPeopleVaccinated/dea.population)*100  
  FROM PortfolioProject..CovidDeaths AS dea
  JOIN PortfolioProject..CovidVaccinations AS vac
	  ON dea.location = vac.location AND
		 dea.date = vac.date
 WHERE (dea.continent is not null) AND (vac.continent is not null)
 ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
  FROM #PercentPopulationVaccinated;


-- Creating View to store data for later visualizations
--DROP VIEW IF EXISTS PercentPopulationVaccinated;
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
		,SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY vac.location ORDER BY vac.date) AS RollingPeopleVaccinated   --�Q�� PARTITOIN BY
	  --, (RollingPeopleVaccinated/dea.population)*100  
  FROM PortfolioProject..CovidDeaths AS dea
  JOIN PortfolioProject..CovidVaccinations AS vac
	  ON dea.location = vac.location AND
		 dea.date = vac.date
 WHERE (dea.continent is not null) AND (vac.continent is not null)
 --ORDER BY 2,3



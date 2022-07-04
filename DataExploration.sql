-- Confirming the Data
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 3, 4;    -- Order First by the 3rd column then by the 4th (indexing is from 1)	

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3, 4;

--------------------------------------------------------------------------------------------
-- Select the Data we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 1, 2;

--------------------------------------------------------------------------------------------
-- Looking at the Total Cases vs Total Deaths (Percentage of people who died w.r.t the total cases)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'INDIA' 						-- LIKE '%states%'
ORDER BY 1, 2
--> Shows the Likelihood of dying if one contract COVID in the specific Country
-->> As of July 2nd 2022, there is a 2% chance that one might die due to COVID in INDIA.

--------------------------------------------------------------------------------------------
-- Looking at the Total Cases vs Population
SELECT location, date, total_cases, population, (total_cases/population)*100 AS PopulationPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'INDIA' 						-- LIKE '%states%'
ORDER BY 1, 2
--> Shows what Percentage of the population has gotten COVID
-->> As of July 2nd 2022, 3% of the populationhas been confirmed of having COVID in INDIA.

--------------------------------------------------------------------------------------------
-- What country has the higgest Infection Rate (total_cases) compared to Population
Select location, population, MAX(total_cases) AS HighestInfectedCount, MAX((total_cases/population))*100 AS InfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER  BY InfectedPopulationPercentage DESC
--> What Percentage of your Population has got COVID

--------------------------------------------------------------------------------------------
-- Showing Countries with highest Death Count
Select location, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY HighestDeathCount DESC

--------------------------------------------------------------------------------------------
-- Showing Data of Deaths for each Continent
SELECT continent, SUM(HighestDeathCount) AS TotalDeaths FROM
(
Select continent, location, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY continent, location
) subquery1									-- Add an alias to the subquery (Standard SQL Practice)
GROUP BY continent
ORDER BY TotalDeaths DESC

--Select location, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount
--FROM PortfolioProject..CovidDeaths
--WHERE continent is NULL
--GROUP BY location

--------------------------------------------------------------------------------------------
-- Global Numbers (Calculate everything around the World)
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentages
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL					-- This way we will include only the country numbers(NOT world Numbers)
GROUP BY date
ORDER BY 1
--<> INFERENCE: When we have 100 total cases and 1 death on 23rd January 2020, then our Death Percentage is 1% across the World. i.e. There is 1% chance that a person with COVID can die on 23rd January 2020

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentages
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--<> INFERENCE: across the World if we are infected with COVID, then our Death Percentage is 1.1%.

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
-- View the vaccinated Table
SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3, 4;

--------------------------------------------------------------------------------------------
-- Join the 2 Tables and look at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingTotalVaccination
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--------- USE CTE (This is a Temporary Table that is created) We use it for CREATING the VaccinatedPercentage Column
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccination, RollingTotalVaccination)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingTotalVaccination
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT Continent, Location, Population, (MAX(RollingTotalVaccination)/Population)*100 AS VaccinatedPercentage
FROM PopvsVac
GROUP BY Continent, Location, Population
ORDER BY 1,2

--------- USE TEMP TABLE (This is an efficient way, when we need to ALTER the table)
DROP TABLE IF EXISTS #VaccinatedPopulationPercentage
CREATE TABLE #VaccinatedPopulationPercentage
(
Continent nvarchar(255), 
Location nvarchar(255), 
Date datetime, 
Population numeric, 
New_Vaccination numeric, 
RollingTotalVaccination numeric
)

INSERT INTO #VaccinatedPopulationPercentage
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingTotalVaccination
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT Continent, Location, Population, (MAX(RollingTotalVaccination)/Population)*100 AS VaccinatedPercentage
FROM #VaccinatedPopulationPercentage
GROUP BY Continent, Location, Population
ORDER BY 1,2

--------------------------------------------------------------------------------------------
-- Create View to Store Data for later Visualizations
CREATE VIEW VaccinatedPopulationPercentage AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingTotalVaccination
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * FROM VaccinatedPopulationPercentage

--------------------------------------------------------------------------------------------
-- Create a View where we can store Information about the Continents
CREATE VIEW ContinentDeaths AS
SELECT continent, SUM(HighestDeathCount) AS TotalDeaths FROM
(
Select continent, location, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY continent, location
) subquery1									-- Add an alias to the subquery (Standard SQL Practice)
GROUP BY continent

SELECT * FROM ContinentDeaths

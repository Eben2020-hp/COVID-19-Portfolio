/*

	Queries For Tableau

*/

-- 1.
SELECT SUM(CAST(new_cases AS int)) AS total_cases, SUM(CONVERT(int, new_deaths)) AS total_deaths, SUM(CAST(total_deaths AS float))/SUM(total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- 2.
SELECT location, SUM(CONVERT(int, new_deaths)) AS  TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT IN ('World', 'European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- 3.
Select location, population, ISNULL(MAX(total_cases), 0) AS HighestInfectedCount, ISNULL(MAX((total_cases/population))*100,0) AS InfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER  BY InfectedPopulationPercentage DESC

-- 4.
Select location, population, date, ISNULL(MAX(total_cases),0) AS HighestInfectedCount, ISNULL(MAX((total_cases/population))*100,0) AS InfectedPopulationPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY location, population, date
ORDER  BY InfectedPopulationPercentage DESC

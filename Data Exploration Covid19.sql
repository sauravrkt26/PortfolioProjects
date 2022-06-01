/*
	DATA EXPLORATION USING COVID-19 DATA
	SKILLS USED: Data Type Conversion, Aggregate Functions, Window Functions, Joins, CTEs, Temp tables, Views.
	Date of data extraction: 05-05-2022
	Viz: https://public.tableau.com/app/profile/saurav.pandey8138/
	
*/

SELECT * 
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT * 
FROM PortfolioProject1..CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3,4

-- Selecting Data that we will only need for this project

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Analyzing Total Cases vs Total Deaths
--Likelihood of dying if you get Covid in a particular country (we used USA as an example)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject1..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

--Analyzing Total Covid Cases vs Population 
--Showing what percent of population got Covid as time passed on

SELECT location, date, total_cases, population, (total_cases/population)*100 AS InfectedPercentage
FROM PortfolioProject1..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

--Looking at countries with highest infection rate

SELECT location, MAX(total_cases) as TotalInfection, MAX(population) as TotalPopulation, MAX(total_cases/population)*100 AS InfectedPercentage
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectedPercentage desc

--Looking at countries with infection rate by date

SELECT location, date, population, MAX(total_cases) as TotalInfection, MAX(total_cases/population)*100 AS InfectedPercentage
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population, date
ORDER BY 1,2

--Showing countries with highest death count rate

SELECT location, MAX(CAST(total_deaths as INT)) as TotalDeaths, MAX(population) as TotalPopulation, MAX(total_deaths/population)*100 AS DeathPercentage
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY DeathPercentage desc

--Showing CONTINENTS with highest death count

SELECT location, MAX(CAST(total_deaths as INT)) as TotalDeathCount
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NULL
AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount desc

--GLOBAL NUMBERS
--New Cases to Death Rate by Date 

SELECT date, SUM(new_cases) AS NewCases , SUM(CAST(new_deaths AS INT)) AS NewDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) *100 as DeathRate
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
AND location NOT LIKE '%income%'
GROUP BY date
ORDER BY date

--Total Cases and Death Rate to date(05-05-2022) by continent

SELECT location, SUM(new_cases) AS TotalCases , SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) *100 as DeathRate
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NULL
AND location NOT LIKE '%income%'
AND location NOT IN ('European Union','International','World')
GROUP BY location
ORDER BY location

--Total Cases and Death Rate to date(05-05-2022) GLOBAL

SELECT  SUM(new_cases) AS TotalCases , SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) *100 as DeathRate
FROM PortfolioProject1..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY location
--ORDER BY DeathRate desc


--JOINING TABLES
-- Looking at total population vs vaccinations per day, window function needed

SELECT TOP 100000 cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(CAST(cv.new_vaccinations AS BIGINT)) OVER  (PARTITION BY cd.location ORDER BY cd.date) AS TotalVaxedtoDate
FROM PortfolioProject1..CovidDeaths cd
JOIN PortfolioProject1..CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 1,2

--Using CTE to determine what % of population are Vaccinated to date

WITH PopvsVac(Location, Date, Population, TotalVaxedtoDate)
AS
(
	SELECT TOP 100000 cd.location, cd.date, cd.population,  
		SUM(CAST(cv.new_vaccinations AS BIGINT)) OVER  (PARTITION BY cd.location ORDER BY cd.date) AS TotalVaxedtoDate
	FROM PortfolioProject1..CovidDeaths cd
	JOIN PortfolioProject1..CovidVaccinations cv
		ON cd.location = cv.location
		AND cd.date = cv.date
	WHERE cd.continent IS NOT NULL
	ORDER BY 1,2
)

SELECT *, TotalVaxedtoDate/Population*100 AS Vac_Pop_Percent
FROM PopvsVac

--Using a Temp-table to determine what % of population are Vaccinated to date

DROP TABLE IF EXISTS  #temp_vac
CREATE TABLE #temp_vac
	(	Location nvarchar(60),
		Date datetime, 
		Population numeric,
		TotalVaxedtoDate numeric
	)

INSERT INTO #temp_vac

	SELECT TOP 100000 cd.location, cd.date, cd.population,  
		SUM(CAST(cv.new_vaccinations AS BIGINT)) OVER  (PARTITION BY cd.location ORDER BY cd.date) AS TotalVaxedtoDate
	FROM PortfolioProject1..CovidDeaths cd
	JOIN PortfolioProject1..CovidVaccinations cv
		ON cd.location = cv.location
		AND cd.date = cv.date
	WHERE cd.continent IS NOT NULL
	ORDER BY 1,2

SELECT *, TotalVaxedtoDate/Population*100 AS Vac_Pop_Percent
FROM #temp_vac
ORDER BY 1,2

--Creating VIEW to store data
--Data for showing CONTINENTS with highest death count 

CREATE VIEW DeathCountbyContinent 
AS
(
	SELECT location, MAX(CAST(total_deaths as INT)) as TotalDeathCount
	FROM PortfolioProject1..CovidDeaths
	WHERE continent IS NULL
	AND location NOT LIKE '%income%'
	GROUP BY location
	--ORDER BY TotalDeathCount desc
)

SELECT * FROM DeathCountbyContinent
ORDER BY TotalDeathCount desc

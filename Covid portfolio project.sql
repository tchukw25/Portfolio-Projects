SELECT * 
FROM Portfolio_Project..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 3,4
;

SELECT *
FROM Portfolio_Project..CovidVaccinations
ORDER BY 3,4;

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project..CovidDeaths
ORDER BY 1,2;

ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN total_cases numeric;

ALTER TABLE [Portfolio Project]..CovidDeaths
ALTER COLUMN total_deaths numeric;

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in a certain country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS percent_dead
FROM Portfolio_Project..CovidDeaths
ORDER BY 1,2
;

-- Shows what percentage of population infected with Covid

SELECT Location, date, total_cases, Population, (total_cases/Population)*100 AS infected_percentage
FROM Portfolio_Project..CovidDeaths
ORDER BY 1,2
;


--Looking at countries with highest infection rate compared to the population

SELECT Location, Population, MAX(total_cases) as highest_infection_count, MAX((total_cases/Population))*100 AS highest_infected_percentage
FROM Portfolio_Project..CovidDeaths
GROUP BY Location, Population
ORDER BY highest_infected_percentage desc
;

--Showing countries with highest death count per population

SELECT Location, MAX(total_deaths) as total_death_count
FROM Portfolio_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY total_death_count desc

--Breaking things down by continent

--Shows highest death count by continent

SELECT continent, MAX(total_deaths) as total_death_count
FROM Portfolio_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

-- Global numbers
SET ANSI_WARNINGS OFF
GO

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, 
SUM(new_deaths)/ NULLIF(SUM(new_cases), 0) * 100 AS death_percentage
FROM Portfolio_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2
;

--Global cases, deaths, and death percentage
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, 
SUM(new_deaths)/ NULLIF(SUM(new_cases), 0) * 100 AS death_percentage
FROM Portfolio_Project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2
;

-- Looking at total population vs. vaccinations
SELECT * FROM Portfolio_Project..CovidDeaths AS death
JOIN Portfolio_Project..CovidVaccinations AS vax
ON death.location = vax.location 
AND death.date = vax.date
;


SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations,
SUM(CAST(vax.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS 
rolling_vax_count 
FROM Portfolio_Project..CovidDeaths AS death
JOIN Portfolio_Project..CovidVaccinations AS vax
ON death.location = vax.location
AND death.date = vax.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3
;

-- Using a CTE

WITH pop_vs_vax (continent, location, date, population, new_vaccinations, rolling_vax_count)
AS
(
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations,
SUM(CAST(vax.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS 
rolling_vax_count 
FROM Portfolio_Project..CovidDeaths AS death
JOIN Portfolio_Project..CovidVaccinations AS vax
ON death.location = vax.location
AND death.date = vax.date
WHERE death.continent IS NOT NULL
)

SELECT *, (rolling_vax_count/population) * 100 AS rolling_percentage_vax_pop FROM pop_vs_vax

--Using a Temp table

DROP TABLE IF exists percent_pop_vaxxed
CREATE TABLE percent_pop_vaxxed
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population float,
new_vaccinations nvarchar(255),
rolling_vax_count bigint
)

INSERT INTO percent_pop_vaxxed
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations,
SUM(CAST(vax.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS 
rolling_vax_count
FROM Portfolio_Project..CovidDeaths AS death
JOIN Portfolio_Project..CovidVaccinations AS vax
ON death.location = vax.location
AND death.date = vax.date
WHERE death.continent IS NOT NULL

SELECT *, (rolling_vax_count/population) * 100 AS rolling_percentage_vax_pop 
FROM percent_pop_vaxxed;

DROP VIEW percent_vaxxed_population
DROP VIEW infection_vs_pop
DROP VIEW highest_death_count_per_pop
DROP VIEW global_numbers

-- Creating views to use for tableau portion
USE Portfolio_Project
GO
CREATE VIEW percent_vaxxed_population
AS
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations, SUM(CAST(vax.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS 
rolling_vax_count, (MAX(CAST(people_vaccinated AS numeric)/population)) * 100 AS vax_percentage
FROM Portfolio_Project..CovidDeaths AS death
JOIN Portfolio_Project..CovidVaccinations AS vax
ON death.location = vax.location
AND death.date = vax.date
WHERE death.continent IS NOT NULL
AND death.location not in ('World', 'Africa', 'International', 'European Union')
GROUP BY death.continent, death.location, death.date, death.population, vax.new_vaccinations;
GO 

USE Portfolio_Project
GO
CREATE VIEW infection_vs_pop 
AS
SELECT continent, Location, Population, date, MAX(total_cases) as highest_infection_count, ((total_cases/population))*100 AS infected_percentage
FROM Portfolio_Project..CovidDeaths
WHERE location not in ('World', 'Africa', 'International', 'European Union')
AND continent IS NOT NULL
GROUP BY continent, Location, Population, date, ((total_cases/population))*100
--ORDER BY highest_infected_percentage desc;
GO

USE Portfolio_Project
GO
CREATE VIEW highest_death_count_per_pop
AS
SELECT Location, MAX(total_deaths) as total_death_count
FROM Portfolio_Project..CovidDeaths
WHERE continent IS NOT NULL
AND location not in ('World', 'Africa', 'International', 'European Union')
GROUP BY Location
--ORDER BY total_death_count desc;
GO

USE Portfolio_Project
GO
CREATE VIEW global_numbers AS
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, 
SUM(new_deaths)/ NULLIF(SUM(new_cases), 0) * 100 AS death_percentage
FROM Portfolio_Project..CovidDeaths
WHERE continent IS NOT NULL
--ORDER BY 1,2
;
GO
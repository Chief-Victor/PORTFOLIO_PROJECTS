-- AS OF 24th MARCH 2022, THIS DATA IS UP TO-DATE

-- VIEW THE THE DATA AVAILABLE

	SELECT *
	FROM COVID.dbo.COVIDDEATH$

	SELECT *
	FROM COVID.dbo.CovidVaccination$

-- SELECT THE DATA WE NEED

	SELECT continent, location, date, population, total_cases, total_deaths
	FROM COVID.dbo.COVIDDEATH$
	WHERE continent is not null
	ORDER BY 1,2

-- TOTAL CASES VS TOTAL DEATHS
-- WHAT IS THE CHANCE OF DIEING FROM COVID COMPLICATION IN YOUR LOCATION
	
	SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
	FROM COVID.dbo.COVIDDEATH$
	WHERE continent is not null AND Location LIKE '%States%'
	-- You can search your location by inserting the name of your country in '%States%'
	ORDER BY 1,2

-- TOTAL CASES VS POPULATION 
-- WHAT PERCENTAGE OF THE POPULATION IN A LOCATION HAVE TESTED POSITIVE

	SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentagePopulationInfected
	FROM COVID.dbo.COVIDDEATH$
	WHERE continent is not null AND Location LIKE '%States%'
	-- You can search your location by inserting the name of your country in '%States%'
	ORDER BY 1,2

-- COUNTRIES WITH HIGHEST COVID INFECTION RATE 
-- This is not neccessarilly the count of number of cases but the number of cases with respect to the population of the country.
	
	SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentagePopulationInfected
	FROM COVID.dbo.COVIDDEATH$
	WHERE continent is not null 
	--AND Location LIKE '%States%'
	-- You can search your location by inserting the name of your country in '%States%'
	GROUP BY Location, population
	ORDER BY PercentagePopulationInfected DESC

-- COUNTRIES WITH HIGHEST DEATH COUNT  

	SELECT location, population, MAX(CONVERT(INT,total_deaths)) AS TotalDeathCount
	FROM COVID.dbo.COVIDDEATH$
	WHERE continent is not null 
	--AND Location LIKE '%States%'
	-- You can search your location by inserting the name of your country in '%States%'
	GROUP BY Location, population
	ORDER BY TotalDeathCount DESC

-- COVID CASES ON DIFFERENT CONTINENTS 

	SELECT continent, MAX(total_cases) AS TotalCasesPerContinent, MAX(CONVERT(INT,total_deaths)) AS TotalDeathsPerContinents
	FROM COVID.dbo.COVIDDEATH$
	WHERE continent is not null 
	--AND Location LIKE '%States%'
	-- You can search your location by inserting the name of your country in '%States%'
	GROUP BY continent
	ORDER BY TotalDeathsPerContinents DESC

--- NB: WHERE CONTINENT IS NULL SOME DATA WERE ENTERED THAT WILL SHOW THE COMPLETE REALITY, 
-- HOWEVER FOR THE SAKE OF VISUALIZATION ON TABLUE, THE QUERY ABOVE IS BETTER 
-- SO FOR SAKE OF CLARITY LETS WRITE QUERY TO SHOW OTHER DATA ENTERED
	
	SELECT location, MAX(total_cases) AS TotalCasesPerContinent, MAX(CONVERT(INT,total_deaths)) AS TotalDeathsPerContinents
	FROM COVID.dbo.COVIDDEATH$
	WHERE continent is null 
	--AND Location LIKE '%States%'
	-- You can search your location by inserting the name of your country in '%States%'
	GROUP BY location
	ORDER BY TotalDeathsPerContinents DESC

-- GLOBAL NUMBERS
-- Given the world population and the number of tested positive cases and deaths, what is the chance of death now?

	SELECT SUM(population) AS Totalpopulation, SUM(new_cases) AS TotalCases, SUM(CONVERT(INT,new_deaths)) AS TotalDeaths, 
	SUM(CONVERT(INT,new_deaths))/SUM(new_cases)*100 AS DeathPercentage
	FROM COVID.dbo.COVIDDEATH$
	--WHERE location like '%states%' 
	WHERE continent is not null
	--GROUP BY date
	ORDER BY 1,2

-- WHAT POPULATION OF THE WORLD IS VACCINATED?
-- TO DO THIS, WRITE A QUERY TO JOIN THE TWO TABLES, AND THEN USING CTE OR TEMPORARY TABLE.

	SELECT *
	FROM COVID.dbo.COVIDDEATH$ Det
	JOIN COVID.dbo.CovidVaccination$ Vac
	ON Det.location = Vac.location
	and Det.date = Vac.date 

-- WHEN DID COUNTRIES START TAKING VACCINES?
	SELECT Det.continent, Det.location, Det.date, Det.population, Vac.new_vaccinations
	, SUM(CONVERT(bigint,Vac.new_vaccinations)) OVER (Partition BY Det.location ORDER BY 
	Det.location) AS RollingPeopleVaccinated
	FROM COVID.dbo.COVIDDEATH$ Det
	JOIN COVID.dbo.CovidVaccination$ Vac
	ON Det.location = Vac.location
	and Det.date = Vac.date 
	WHERE Det.continent is not null
	ORDER BY 2,3

--- USING CTE(COMMON TABLE EXPRESSION) 
-- CTE is a temporary named result set that you can reference within a SELECT, INSERT, UPDATE, or DELETE statement. 
--You can also use a CTE in a CREATE a view, as part of the view’s SELECT query. 

	WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated) 
	AS
	(
	SELECT Det.continent, Det.location, Det.date, Det.population, Vac.new_vaccinations
	, SUM(CONVERT(bigint,Vac.new_vaccinations)) OVER (Partition BY Det.location ORDER BY 
	Det.location) AS RollingPeopleVaccinated
	FROM COVID.dbo.COVIDDEATH$ Det
	JOIN COVID.dbo.CovidVaccination$ Vac
	ON Det.location = Vac.location
	and Det.date = Vac.date 
	WHERE Det.continent is not null
	--ORDER BY 2,3
	)
	SELECT *, (RollingPeopleVaccinated/population)*100 PercentagePoPVaccinated
	FROM PopvsVac

-- USING TEMPORARY TABLE 
	
	DROP TABLE IF exists #PercentagePoPVaccinated
	CREATE TABLE #PercentagePoPVaccinated
	(
	continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
	)

	INSERT into #PercentagePoPVaccinated
	SELECT Det.continent, Det.location, Det.date, Det.population, Vac.new_vaccinations
	, SUM(CONVERT(bigint,Vac.new_vaccinations)) OVER (Partition BY Det.location ORDER BY 
	Det.location) AS RollingPeopleVaccinated
	FROM COVID.dbo.COVIDDEATH$ Det
	JOIN COVID.dbo.CovidVaccination$ Vac
	ON Det.location = Vac.location
	and Det.date = Vac.date 
	WHERE Det.continent is not null
	--ORDER BY 2,3

	SELECT *, (RollingPeopleVaccinated/population)*100 PercentagePoPVaccinated
	FROM #PercentagePoPVaccinated

-- NB: CTE AND TEMPORARY TABLE WILL GIVE THE SAME RESULT

-- CREATE VIEW FOR VISUALIZATION
	
	Create View PercentagePoPVaccinated as
	SELECT Det.continent, Det.location, Det.date, Det.population, Vac.new_vaccinations
	, SUM(CONVERT(bigint,Vac.new_vaccinations)) OVER (Partition BY Det.location ORDER BY 
	Det.location) AS RollingPeopleVaccinated
	FROM COVID.dbo.COVIDDEATH$ Det
	JOIN COVID.dbo.CovidVaccination$ Vac
	ON Det.location = Vac.location
	and Det.date = Vac.date 
	WHERE Det.continent is not null
	--ORDER BY 2,3


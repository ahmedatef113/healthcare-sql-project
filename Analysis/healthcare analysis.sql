----------------Number of Patients by Gender-------------------

SELECT p.gender,
	   COUNT(p.patient_key) AS TotalPatients
FROM dbo.dim_patient as p
GROUP BY p.gender;

--------------Number of Patients By Gender And Age Group-----------------

SELECT P.gender,P.age_group,COUNT(p.patient_key) AS TotalPatients
FROM dbo.dim_patient AS p
GROUP BY p.gender,p.age_group
ORDER BY TotalPatients DESC;


-----------Number of encounters by years and months------------

SELECT d.year,d.month_name,COUNT(en.encounter_id) AS NumbersOfEncounters
FROM dbo.fact_patient_encounters as en
JOIN dbo.dim_date as d
on en.date_key = d.date_key
GROUP BY d.year,d.month_name
ORDER BY d.year, d.month_name;

----------------Find the total cost (total_cost) for each facility_name-------------

SELECT f.facility_name,SUM(en.total_cost) AS TotalCost
FROM dbo.dim_facility AS f
JOIN dbo.fact_patient_encounters AS en
on f.facility_key = en.facility_key
GROUP BY f.facility_name
ORDER BY TotalCost DESC;


--------------------Top 5 diagnoses in terms of total cost------------


SELECT TOP 5 
       d.condition_name,
       SUM(en.total_cost) AS TotalCost
FROM dbo.dim_diagnosis AS d
JOIN dbo.fact_patient_encounters AS en
ON d.diagnosis_key = en.diagnosis_key
GROUP BY d.condition_name
ORDER BY TotalCost DESC;


--------------Average length of stay (length_of_stay) per facility_type-------------------

SELECT f.facility_type,AVG(en.length_of_stay) AS AverageLengthOfStay
FROM dbo.fact_patient_encounters AS en
JOIN dbo.dim_facility AS f
ON en.facility_key = f.facility_key
GROUP BY f.facility_type
ORDER BY AverageLengthOfStay DESC;

--------------Give the total revenue for each provider_name-----------------

SELECT p.provider_name,SUM(c.payer_paid + c.patient_paid) AS TotalRevenue
FROM dbo.dim_provider AS p
JOIN dbo.fact_claims AS c
ON p.provider_key = c.provider_key
GROUP BY p.provider_name
ORDER BY TotalRevenue DESC;

----------------------Number of encounters per provider_name---------------------

SELECT p.provider_name,COUNT(en.encounter_id) AS NumberOfEncounters
FROM dbo.dim_provider AS p
JOIN dbo.fact_patient_encounters AS en
ON p.provider_key = en.provider_key
GROUP BY p.provider_name
HAVING COUNT(en.encounter_id) > 100
ORDER BY NumberOfEncounters DESC;

----------Top 3 patients in terms of total cost paid-------------------

SELECT TOP 3 
       c.patient_key,
       SUM(c.patient_paid + c.payer_paid) AS totalcost
FROM dbo.fact_claims AS c
GROUP BY c.patient_key
ORDER BY totalcost DESC;

------------For each diagnosis, the number of encounters and the average total cost------------

SELECT 
       d.condition_name,
       COUNT(en.encounter_id) AS NumberOfEncounters,
       AVG(en.total_cost) AS AvgTotalCost
FROM dbo.fact_patient_encounters AS en
JOIN dbo.dim_diagnosis AS d
ON en.diagnosis_key = d.diagnosis_key
GROUP BY d.condition_name
ORDER BY AvgTotalCost DESC;

-----------------For each patient, the total number of encounters and the total amount paid are recorded.----------------------

WITH encounters_cte AS (
    SELECT 
        patient_key,
        COUNT(encounter_id) AS total_encounters
    FROM dbo.fact_patient_encounters
    GROUP BY patient_key
),
claims_cte AS (
    SELECT 
        patient_key,
        SUM(payer_paid + patient_paid) AS total_paid
    FROM dbo.fact_claims
    GROUP BY patient_key
)

SELECT 
       e.patient_key,
       e.total_encounters,
       c.total_paid
FROM encounters_cte e
JOIN claims_cte c
ON e.patient_key = c.patient_key
ORDER BY total_paid DESC;

-----------------Top 3 providers each year in terms of total revenue------------------

SELECT *
FROM (
    SELECT 
           p.provider_name,
           d.year,
           SUM(c.patient_paid + c.payer_paid) AS TotalRevenue,
           RANK() OVER(PARTITION BY d.year 
                       ORDER BY SUM(c.patient_paid + c.payer_paid) DESC) AS Ran
    FROM dbo.dim_provider AS p
    JOIN dbo.fact_claims AS c
        ON p.provider_key = c.provider_key
    JOIN dbo.dim_date AS d
        ON c.date_key = d.date_key
    GROUP BY p.provider_name, d.year
) t
WHERE Ran <= 3;

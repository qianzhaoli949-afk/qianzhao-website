-- One designated parent and one child belong to each origin family in 2000.
-- Their later income records follow their person IDs, even after the child moves.
WITH pairs AS (
    SELECT p.family_id AS origin_family_id,
           p.person_id AS parent_id,
           c.person_id AS child_id
    FROM household AS p
    JOIN household AS c
      ON p.family_id = c.family_id AND p.year = c.year
    WHERE p.year = 2000
      AND p.relationship = 'parent'
      AND c.relationship = 'child'
      AND p.person_id <> c.person_id
),
parent_income AS (
    SELECT person_id,
           MAX(CASE WHEN age = 45 THEN real_income END) AS one_year,
           AVG(CASE WHEN age BETWEEN 44 AND 48 THEN real_income END) AS five_year,
           SUM(CASE WHEN age BETWEEN 44 AND 48 THEN 1 ELSE 0 END) AS years_observed
    FROM income
    GROUP BY person_id
),
child_income AS (
    SELECT person_id,
           MAX(CASE WHEN age = 25 THEN real_income END) AS early_one_year,
           AVG(CASE WHEN age BETWEEN 25 AND 29 THEN real_income END) AS early_five_year,
           MAX(CASE WHEN age = 37 THEN real_income END) AS mid_one_year,
           AVG(CASE WHEN age BETWEEN 35 AND 39 THEN real_income END) AS mid_five_year,
           SUM(CASE WHEN age BETWEEN 25 AND 29 THEN 1 ELSE 0 END) AS early_years,
           SUM(CASE WHEN age BETWEEN 35 AND 39 THEN 1 ELSE 0 END) AS mid_years
    FROM income
    GROUP BY person_id
)
SELECT pairs.origin_family_id,
       pairs.parent_id,
       pairs.child_id,
       parent_income.one_year AS parent_one_year,
       parent_income.five_year AS parent_five_year,
       child_income.early_one_year,
       child_income.early_five_year,
       child_income.mid_one_year,
       child_income.mid_five_year
FROM pairs
JOIN parent_income ON parent_income.person_id = pairs.parent_id
JOIN child_income ON child_income.person_id = pairs.child_id
WHERE parent_income.years_observed = 5
  AND child_income.early_years = 5
  AND child_income.mid_years = 5
  AND parent_income.one_year > 0
  AND child_income.early_one_year > 0
  AND child_income.mid_one_year > 0
ORDER BY pairs.origin_family_id;

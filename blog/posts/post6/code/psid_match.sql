WITH mother_child AS (
    SELECT p.child_1968, p.child_person,
           p.mother_1968, p.mother_person
    FROM pid AS p
    JOIN person AS child
      ON child.id_1968 = p.child_1968
     AND child.person_no = p.child_person
    JOIN person AS mother
      ON mother.id_1968 = p.mother_1968
     AND mother.person_no = p.mother_person
    WHERE p.mother_1968 > 0
      AND p.mother_person BETWEEN 1 AND 995
      AND child.age_2023 BETWEEN 30 AND 40
      AND mother.age_2005 BETWEEN 35 AND 70
      AND mother.age_2005 + 18 - child.age_2023 BETWEEN 15 AND 45
),
parent_income AS (
    SELECT id_1968, person_no,
           MAX(CASE WHEN income_year = 2000 THEN real_income END) AS p2000,
           MAX(CASE WHEN income_year = 2002 THEN real_income END) AS p2002,
           MAX(CASE WHEN income_year = 2004 THEN real_income END) AS p2004,
           AVG(real_income) AS parent_avg,
           COUNT(*) AS parent_years
    FROM income
    WHERE income_year IN (2000, 2002, 2004)
    GROUP BY id_1968, person_no
),
child_income AS (
    SELECT id_1968, person_no,
           MAX(CASE WHEN income_year = 2018 THEN real_income END) AS c2018,
           MAX(CASE WHEN income_year = 2020 THEN real_income END) AS c2020,
           MAX(CASE WHEN income_year = 2022 THEN real_income END) AS c2022,
           AVG(real_income) AS child_avg,
           COUNT(*) AS child_years
    FROM income
    WHERE income_year IN (2018, 2020, 2022)
    GROUP BY id_1968, person_no
)
SELECT p.p2000, p.p2002, p.p2004, p.parent_avg,
       c.c2018, c.c2020, c.c2022, c.child_avg
FROM mother_child AS link
JOIN parent_income AS p
  ON p.id_1968 = link.mother_1968
 AND p.person_no = link.mother_person
JOIN child_income AS c
  ON c.id_1968 = link.child_1968
 AND c.person_no = link.child_person
WHERE p.parent_years = 3
  AND c.child_years = 3;

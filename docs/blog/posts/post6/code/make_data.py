"""Create a small, reproducible longitudinal teaching dataset."""

import csv
import math
import random
from pathlib import Path


POST = Path(__file__).resolve().parents[1]
DATA = POST / "data"
FAMILIES = 600
SEED = 20261018
LONG_RUN_ELASTICITY = 0.45


def save_csv(name, fields, rows):
    DATA.mkdir(parents=True, exist_ok=True)
    with (DATA / name).open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(fields)
        writer.writerows(rows)


def main():
    rng = random.Random(SEED)
    people, household, incomes, long_run = [], [], [], []

    for number in range(1, FAMILIES + 1):
        origin = f"F{number:04d}"
        parent = f"P{number:04d}"
        child = f"C{number:04d}"
        people.extend(((parent, 1956), (child, 1985)))
        household.extend(((origin, parent, 2000, "parent"),
                          (origin, child, 2000, "child")))

        parent_log = rng.gauss(10.9, 0.55)
        child_log = 10.8 + LONG_RUN_ELASTICITY * (parent_log - 10.9)
        child_log += rng.gauss(0, 0.38)
        long_run.append((origin, parent_log, child_log))

        for age in range(44, 49):
            year = 1956 + age
            log_income = parent_log + 0.025 * (age - 46)
            log_income += rng.gauss(0, 0.30)
            incomes.append((parent, origin, year, age,
                            round(math.exp(log_income), 2)))

        for age in (*range(25, 30), *range(35, 40)):
            year = 1985 + age
            adult_family = f"A{number:04d}"
            career_factor = min(1.0, 0.50 + 0.05 * (age - 25))
            age_level = -0.50 + 0.05 * min(age - 25, 10)
            log_income = 10.8 + career_factor * (child_log - 10.8)
            log_income += age_level + rng.gauss(0, 0.30)
            incomes.append((child, adult_family, year, age,
                            round(math.exp(log_income), 2)))

    save_csv("people.csv", ("person_id", "birth_year"), people)
    save_csv("household.csv", ("family_id", "person_id", "year", "relationship"),
             household)
    save_csv("income.csv", ("person_id", "family_id", "year", "age", "real_income"),
             incomes)
    save_csv("long_run.csv", ("origin_family_id", "parent_log", "child_log"),
             long_run)
    print(f"Created {FAMILIES} simulated families in {DATA}")


if __name__ == "__main__":
    main()

"""Match generations in SQLite and compare income elasticities."""

import csv
import html
import math
import sqlite3
from pathlib import Path


POST = Path(__file__).resolve().parents[1]
DATA = POST / "data"
RESULTS = POST / "results"


def load_csv(connection, name, statement, fields, convert):
    with (DATA / name).open(newline="", encoding="utf-8") as file:
        rows = csv.DictReader(file)
        connection.executemany(statement,
                               (tuple(convert[field](row[field]) for field in fields)
                                for row in rows))


def slope(pairs):
    xs = [math.log(parent) for parent, _ in pairs]
    ys = [math.log(child) for _, child in pairs]
    x_mean = sum(xs) / len(xs)
    y_mean = sum(ys) / len(ys)
    numerator = sum((x - x_mean) * (y - y_mean) for x, y in zip(xs, ys))
    denominator = sum((x - x_mean) ** 2 for x in xs)
    return numerator / denominator


def write_csv(name, fields, rows):
    RESULTS.mkdir(parents=True, exist_ok=True)
    with (RESULTS / name).open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(fields)
        writer.writerows(rows)


def draw_chart(estimates, benchmark):
    width, height = 910, 430
    left, right, top = 330, 820, 75
    x_limit = 0.60
    x = lambda value: left + (right - left) * value / x_limit
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
        '<title id="title">Income elasticity across four measurement choices</title>',
        '<desc id="desc">The early career estimates are lower than the midcareer estimates. Five year averages differ from single year measures. A dashed line marks the simulated long run benchmark.</desc>',
        '<rect width="100%" height="100%" fill="white"/>',
        '<text x="24" y="32" font-family="Arial, sans-serif" font-size="20" font-weight="bold" fill="#18324c">Estimated intergenerational income elasticity</text>',
    ]
    for tick in range(0, 7):
        value = tick / 10
        position = x(value)
        parts.append(f'<line x1="{position:.1f}" y1="{top}" x2="{position:.1f}" y2="345" stroke="#e4e9ee"/>')
        parts.append(f'<text x="{position:.1f}" y="370" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" fill="#526271">{value:.1f}</text>')
    parts.append(f'<line x1="{x(benchmark):.1f}" y1="{top}" x2="{x(benchmark):.1f}" y2="345" stroke="#6b4c9a" stroke-width="2" stroke-dasharray="7 5"/>')
    parts.append(f'<text x="{x(benchmark):.1f}" y="65" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#6b4c9a">Long-run sample benchmark: {benchmark:.2f}</text>')
    for index, (label, value) in enumerate(estimates):
        y = 115 + index * 63
        color = "#d38438" if index < 2 else "#177e84"
        parts.append(f'<text x="305" y="{y + 5}" text-anchor="end" font-family="Arial, sans-serif" font-size="15" fill="#18324c">{html.escape(label)}</text>')
        parts.append(f'<line x1="{left}" y1="{y}" x2="{x(value):.1f}" y2="{y}" stroke="{color}" stroke-width="8" stroke-linecap="round"/>')
        parts.append(f'<circle cx="{x(value):.1f}" cy="{y}" r="8" fill="{color}"/>')
        if abs(value - benchmark) < 0.05:
            parts.append(f'<text x="{x(value) - 12:.1f}" y="{y - 14}" text-anchor="end" font-family="Arial, sans-serif" font-size="15" font-weight="bold" fill="{color}">{value:.3f}</text>')
        else:
            parts.append(f'<text x="{x(value) + 14:.1f}" y="{y + 5}" font-family="Arial, sans-serif" font-size="15" font-weight="bold" fill="{color}">{value:.3f}</text>')
    parts.append('<text x="24" y="407" font-family="Arial, sans-serif" font-size="12" fill="#526271">Simulated families; identical sample of 600 for all four estimates.</text>')
    parts.append('</svg>')
    (RESULTS / "elasticities.svg").write_text("\n".join(parts), encoding="utf-8")


def main():
    connection = sqlite3.connect(":memory:")
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    connection.executescript("""
        CREATE TABLE people (
            person_id TEXT PRIMARY KEY,
            birth_year INTEGER NOT NULL
        );
        CREATE TABLE household (
            family_id TEXT NOT NULL,
            person_id TEXT NOT NULL REFERENCES people(person_id),
            year INTEGER NOT NULL,
            relationship TEXT NOT NULL CHECK (relationship IN ('parent', 'child')),
            PRIMARY KEY (person_id, year),
            UNIQUE (family_id, year, relationship)
        );
        CREATE TABLE income (
            person_id TEXT NOT NULL REFERENCES people(person_id),
            family_id TEXT NOT NULL,
            year INTEGER NOT NULL,
            age INTEGER NOT NULL,
            real_income REAL NOT NULL CHECK (real_income > 0),
            PRIMARY KEY (person_id, year)
        );
    """)
    load_csv(connection, "people.csv",
             "INSERT INTO people VALUES (?, ?)",
             ("person_id", "birth_year"),
             {"person_id": str, "birth_year": int})
    load_csv(connection, "household.csv",
             "INSERT INTO household VALUES (?, ?, ?, ?)",
             ("family_id", "person_id", "year", "relationship"),
             {"family_id": str, "person_id": str, "year": int, "relationship": str})
    load_csv(connection, "income.csv",
             "INSERT INTO income VALUES (?, ?, ?, ?, ?)",
             ("person_id", "family_id", "year", "age", "real_income"),
             {"person_id": str, "family_id": str, "year": int,
              "age": int, "real_income": float})
    invalid_ages = connection.execute("""
        SELECT COUNT(*) FROM income
        JOIN people USING (person_id)
        WHERE income.age <> income.year - people.birth_year
    """).fetchone()[0]
    if invalid_ages:
        raise ValueError(f"Found {invalid_ages} income rows with inconsistent age and year")

    query = (POST / "code" / "match.sql").read_text(encoding="utf-8")
    matched = [dict(row) for row in connection.execute(query)]
    if len(matched) != 600 or len({row["child_id"] for row in matched}) != 600:
        raise ValueError("Expected exactly 600 unique parent-child pairs with complete income windows")
    for row in matched:
        if not all(value > 0 for key, value in row.items() if key.endswith("year")):
            raise ValueError("Matched income must be positive")

    fields = list(matched[0])
    write_csv("matched.csv", fields, ([row[field] for field in fields] for row in matched))

    designs = [
        ("Age 25, single year", "parent_one_year", "early_one_year"),
        ("Ages 25–29, five years", "parent_five_year", "early_five_year"),
        ("Age 37, single year", "parent_one_year", "mid_one_year"),
        ("Ages 35–39, five years", "parent_five_year", "mid_five_year"),
    ]
    estimates = [(label, slope([(row[p], row[c]) for row in matched]))
                 for label, p, c in designs]
    with (DATA / "long_run.csv").open(newline="", encoding="utf-8") as file:
        long_run = list(csv.DictReader(file))
    if len(long_run) != len(matched):
        raise ValueError("Long-run benchmark must use the same families")
    truth_by_family = {row["origin_family_id"]: row for row in long_run}
    benchmark = slope([(math.exp(float(truth_by_family[row["origin_family_id"]]["parent_log"])),
                        math.exp(float(truth_by_family[row["origin_family_id"]]["child_log"])))
                       for row in matched])
    write_csv("elasticities.csv", ("measure", "families", "elasticity"),
              ((label, len(matched), f"{estimate:.6f}") for label, estimate in estimates))
    draw_chart(estimates, benchmark)
    print(f"Matched {len(matched)} families; long-run sample slope {benchmark:.3f}")
    for label, estimate in estimates:
        print(f"{label}: {estimate:.3f}")
    connection.close()


if __name__ == "__main__":
    main()

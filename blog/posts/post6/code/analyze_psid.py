"""Match PSID birth mothers and adult children, then compare IGE measures.

Requires the two ASCII/Stata-statement extracts described in README.md.
Only aggregate estimates and a chart are written to disk. Individual records
remain in the downloaded ZIP files and in an in-memory SQLite database.
"""

import argparse
import csv
import html
import io
import math
import re
import sqlite3
import zipfile
from pathlib import Path


POST = Path(__file__).resolve().parents[1]
LAYOUT = re.compile(
    r"\b(PID\d+|ER\d+[A-Z0-9]*)\s+(\d+)\s*-\s*(\d+)\b",
    re.IGNORECASE,
)

PARENT_WAVES = ((2000, "ER33601", "ER33602", "ER33603", "ER20456"),
                (2002, "ER33701", "ER33702", "ER33703", "ER24099"),
                (2004, "ER33801", "ER33802", "ER33803", "ER28037"))
CHILD_WAVES = ((2018, "ER34701", "ER34702", "ER34703", "ER77448"),
               (2020, "ER34901", "ER34902", "ER34903", "ER81775"),
               (2022, "ER35101", "ER35102", "ER35103", "ER85629"))
WAVES = PARENT_WAVES + CHILD_WAVES
PERSON_FIELDS = {"ER30001", "ER30002", "ER33804", "ER35104"}
INCOME_FIELDS = PERSON_FIELDS | {name for wave in WAVES for name in wave[1:]}
PID_FIELDS = {"PID2", "PID3", "PID4", "PID5"}


def records_from_zip(path, required):
    """Read selected integer columns from PSID's fixed-width ASCII extract."""
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        do_files = [name for name in names if name.lower().endswith(".do")
                    and not name.lower().endswith("_formats.do")]
        data_files = [name for name in names if name.lower().endswith((".txt", ".dat", ".asc"))]
        if len(do_files) != 1 or len(data_files) != 1:
            raise ValueError(f"Expected one Stata .do and one ASCII data file in {path}")
        do_text = archive.read(do_files[0]).decode("latin-1")
        layout = {}
        for line in do_text.splitlines():
            for match in LAYOUT.finditer(line):
                layout[match.group(1).upper()] = (int(match.group(2)) - 1,
                                                   int(match.group(3)))
        missing = required - layout.keys()
        if missing:
            raise ValueError(f"{path.name}: missing layout positions for {sorted(missing)}")
        ordered = sorted(required)
        with archive.open(data_files[0]) as raw:
            for line_number, line in enumerate(io.TextIOWrapper(raw, encoding="latin-1"), 1):
                row = {}
                for name in ordered:
                    start, end = layout[name]
                    value = line[start:end].strip()
                    try:
                        row[name] = int(value) if value else None
                    except ValueError as error:
                        raise ValueError(f"{path.name}, line {line_number}, {name}: {value!r}") from error
                yield row


def cpi_values(path):
    with path.open(newline="", encoding="utf-8") as file:
        values = {int(row["income_year"]): float(row["cpi_annual_average"])
                  for row in csv.DictReader(file)}
    years = {wave[0] for wave in WAVES}
    if not years <= values.keys() or any(values[year] <= 0 for year in years):
        raise ValueError("CPI table lacks a positive value for an income year")
    return values


def load_data(connection, pid_zip, income_zip, cpi):
    connection.executescript("""
        CREATE TABLE pid (
            child_1968 INTEGER, child_person INTEGER,
            mother_1968 INTEGER, mother_person INTEGER
        );
        CREATE TABLE person (
            id_1968 INTEGER, person_no INTEGER,
            age_2005 INTEGER, age_2023 INTEGER,
            PRIMARY KEY (id_1968, person_no)
        );
        CREATE TABLE income (
            id_1968 INTEGER, person_no INTEGER,
            income_year INTEGER, real_income REAL,
            PRIMARY KEY (id_1968, person_no, income_year)
        );
        CREATE INDEX income_person ON income (id_1968, person_no);
    """)
    pid_count = 0
    for row in records_from_zip(pid_zip, PID_FIELDS):
        connection.execute("INSERT INTO pid VALUES (?, ?, ?, ?)",
                           (row["PID2"], row["PID3"], row["PID4"], row["PID5"]))
        pid_count += 1

    person_count = 0
    income_count = 0
    for row in records_from_zip(income_zip, INCOME_FIELDS):
        key = (row["ER30001"], row["ER30002"])
        if not all(isinstance(value, int) and value > 0 for value in key):
            continue
        connection.execute("INSERT INTO person VALUES (?, ?, ?, ?)",
                           (*key, row["ER33804"], row["ER35104"]))
        person_count += 1
        for year, family, sequence, relation, amount in WAVES:
            nominal = row[amount]
            if (row[family] is not None and row[family] > 0
                    and row[sequence] is not None and 1 <= row[sequence] <= 20
                    and row[relation] in (10, 20, 22)
                    and nominal is not None and 0 < nominal < 9_999_997):
                real = nominal * cpi[2022] / cpi[year]
                connection.execute("INSERT INTO income VALUES (?, ?, ?, ?)",
                                   (*key, year, real))
                income_count += 1
    connection.commit()
    return pid_count, person_count, income_count


def slope(rows, parent_field, child_field):
    x = [math.log(row[parent_field]) for row in rows]
    y = [math.log(row[child_field]) for row in rows]
    mx = sum(x) / len(x)
    my = sum(y) / len(y)
    denom = sum((value - mx) ** 2 for value in x)
    return sum((a - mx) * (b - my) for a, b in zip(x, y)) / denom


def draw_chart(estimates, sample_size, path):
    width, height = 960, 450
    left, right = 390, 850
    values = [abs(value) for _, value in estimates]
    limit = max(0.6, math.ceil(max(values) * 10 + 1) / 10)
    x = lambda value: left + (right - left) * value / limit
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
        '<title id="title">IGEs using one year and three-wave income averages</title>',
        '<desc id="desc">Five estimates compare parent and adult-child family income measures using the same matched PSID sample.</desc>',
        '<rect width="100%" height="100%" fill="white"/>',
        '<text x="26" y="34" font-family="Arial,sans-serif" font-size="21" font-weight="bold" fill="#17324c">Intergenerational family-income elasticity</text>',
    ]
    for tick in range(int(limit * 10) + 1):
        value = tick / 10
        place = x(value)
        parts.append(f'<line x1="{place:.1f}" y1="68" x2="{place:.1f}" y2="375" stroke="#e0e8ee"/>')
        parts.append(f'<text x="{place:.1f}" y="397" text-anchor="middle" font-family="Arial,sans-serif" font-size="13" fill="#526271">{value:.1f}</text>')
    for index, (label, estimate) in enumerate(estimates):
        y = 100 + 64 * index
        color = "#187b88" if index == len(estimates) - 1 else "#b56c2e"
        parts.append(f'<text x="365" y="{y + 5}" text-anchor="end" font-family="Arial,sans-serif" font-size="15" fill="#17324c">{html.escape(label)}</text>')
        parts.append(f'<line x1="{left}" y1="{y}" x2="{x(estimate):.1f}" y2="{y}" stroke="{color}" stroke-width="7" stroke-linecap="round"/>')
        parts.append(f'<circle cx="{x(estimate):.1f}" cy="{y}" r="7" fill="{color}"/>')
        parts.append(f'<text x="{x(estimate) + 13:.1f}" y="{y + 5}" font-family="Arial,sans-serif" font-size="15" font-weight="bold" fill="{color}">{estimate:.3f}</text>')
    parts.append(f'<text x="26" y="430" font-family="Arial,sans-serif" font-size="13" fill="#526271">PSID matched sample: {sample_size} mother–child pairs; all amounts in 2022 dollars.</text>')
    parts.append('</svg>')
    path.write_text("\n".join(parts), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pid-zip", type=Path, required=True)
    parser.add_argument("--income-zip", type=Path, required=True)
    args = parser.parse_args()
    cpi = cpi_values(POST / "data" / "cpi_annual.csv")
    connection = sqlite3.connect(":memory:")
    connection.row_factory = sqlite3.Row
    counts = load_data(connection, args.pid_zip, args.income_zip, cpi)
    query = (POST / "code" / "psid_match.sql").read_text(encoding="utf-8")
    rows = [dict(row) for row in connection.execute(query)]
    if len(rows) < 30:
        raise ValueError(f"Only {len(rows)} complete pairs; review extraction and filters")
    designs = [
        ("2000 parent / 2018 child", "p2000", "c2018"),
        ("2000 parent / 2022 child", "p2000", "c2022"),
        ("Parent average / 2018 child", "parent_avg", "c2018"),
        ("Parent average / 2022 child", "parent_avg", "c2022"),
        ("Three-wave averages", "parent_avg", "child_avg"),
    ]
    estimates = [(label, slope(rows, parent, child))
                 for label, parent, child in designs]
    results = POST / "results"
    results.mkdir(exist_ok=True)
    with (results / "psid_estimates.csv").open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(("measure", "mother_child_pairs", "elasticity"))
        writer.writerows((label, len(rows), f"{estimate:.6f}")
                         for label, estimate in estimates)
    draw_chart(estimates, len(rows), results / "psid_elasticities.svg")
    print(f"PID records: {counts[0]:,}; individual records: {counts[1]:,}; usable income records: {counts[2]:,}")
    print(f"Complete mother-child pairs: {len(rows):,}")
    for label, estimate in estimates:
        print(f"{label}: {estimate:.3f}")
    connection.close()


if __name__ == "__main__":
    main()

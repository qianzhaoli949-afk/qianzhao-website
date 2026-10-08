# Post 5 — A Growing State, but Not Everywhere

Question: Where did Pennsylvania gain and lose population between April 2020 and July 2024, and how do natural change and migration contribute?

## Files

| Folder/file | Purpose |
| --- | --- |
| `index.qmd` | Article with data-driven numbers and two figures |
| `code/analyze.R` | Download, validation, county join, calculations, and plot execution |
| `code/plots.R` | County choropleth and selected-county component chart |
| `data/raw/population.csv` | Unmodified national Census Vintage 2024 CSV |
| `data/raw/counties.zip` | Unmodified Census 2024 1:500,000 county shapefile archive |
| `data/manifest.csv` | Exact URLs, UTC retrieval times, MD5 checksums |
| `data/pa-counties.csv` | 67 Pennsylvania counties and calculated measures |
| `data/pa-counties.rds` | Joined sf object in EPSG:5070 |
| `results/figures/` | `population-map.png` and `components.png` |
| `results/session-info.txt` | R and package environment |

## Reproduce

Install R and the GIS package once:

```r
install.packages("sf")
```

Use a current R binary where possible; on Linux, sf may also need system GDAL, GEOS, PROJ, and udunits development libraries. From a terminal in `blog/posts/post5/`, run:

```sh
Rscript code/analyze.R
```

In RStudio, starting from the website project root, the equivalent is:

```r
local({
  previous_directory <- getwd()
  on.exit(setwd(previous_directory))
  setwd("blog/posts/post5")
  source("code/analyze.R")
})
```

The script checks the cached files against their checksums, regenerates both cleaned datasets, and replaces the figures and session information. If a raw file is missing, it downloads that file. A complete cache needs no network access. To intentionally download again, first back up the cache, then run `Rscript code/analyze.R --refresh`. This refreshes the fixed Vintage 2024 sources; it does not switch to newer vintages. No Census API key is required for these public bulk files.

For the standalone reproduction ZIP, unzip it and use that folder as the working directory instead. It includes the raw sources, so the same command works without access to Census servers.

## Render the website

Install Quarto and `install.packages(c("knitr", "rmarkdown"))`. From the website root:

```sh
quarto render blog/posts/post5/index.qmd
quarto render blog/index.qmd
```

The first command reruns analysis from the cache. The output is `docs/blog/posts/post5/index.html`; the second refreshes the blog listing. Publish the source and generated `docs/` files together using Commit then Push. Nothing uploads automatically from RStudio.

## Data and methods

Sources: U.S. Census Bureau [Vintage 2024 county estimates](https://www2.census.gov/programs-surveys/popest/datasets/2020-2024/counties/totals/co-est2024-alldata.csv), [field definitions](https://www2.census.gov/programs-surveys/popest/technical-documentation/file-layouts/2020-2024/CO-EST2024-ALLDATA.pdf), and [2024 cartographic county boundaries](https://www2.census.gov/geo/tiger/GENZ2024/shp/cb_2024_us_county_500k.zip). We deliberately use one fixed vintage, not the latest release. Later releases revise earlier estimates. These are public aggregate data, not individual records.

- Filter state FIPS 42 and county summary level 050; exclude the state total from the map.
- Construct five-digit GEOID from two-digit STATE plus three-digit COUNTY. Join on codes, not county names. Require 67 unique, nonmissing matches and valid, nonempty geometry. Check names after matching as a second guard.
- Transform boundaries to NAD83 / Conus Albers, EPSG:5070, an equal-area projection in meters. Use the simplified 1:500,000 boundaries only for thematic mapping, not precise land measurement.
- Calculate change as `POPESTIMATE2024 - ESTIMATESBASE2020`. Divide by the estimates base and multiply by 100. This covers April 1, 2020–July 1, 2024, not four July-to-July years or an annual rate. The estimates base differs from a raw 2020 census count.
- Sum NATURALCHG, NETMIG, and RESIDUAL for 2020–2024. The 2020 component covers April–June 2020; later components cover July–June years. Natural change is births minus deaths. Net migration combines domestic and international movement. Residual is the remaining accounting adjustment. Require their sum to equal total change for every county.
- Divide cumulative components by the same 2020 base and multiply by 100; these contributions add to the mapped percentage, and differ from Census's published annual rates per 1,000 average residents.
- Reconcile county populations with the Pennsylvania statewide row at both endpoints. State growth uses summed populations, not an unweighted average of county growth rates.

Map classes: below -4%, [-4,-2), [-2,0), [0,2), [2,4), and 4% or above. Colors distinguish declines and gains with a break at zero; classes are descriptive, not significance tests. The seven labeled/charted counties are illustrative locations, not a random sample or a ranking. Interpret all 67 counties using the map and CSV. County land area does not represent population, and county averages hide within-county variation. The data cannot identify migration flows between pairs of counties or establish causes of migration.

Checks for this snapshot: 28 growing counties, 39 declining counties; statewide gain 75,842 (about 0.583%). The script tests population accounting, unique joins, geometry validity, and state totals before saving outputs.

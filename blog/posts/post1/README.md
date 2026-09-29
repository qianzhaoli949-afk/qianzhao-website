# Post 1 — Inferior Goods

**Question:** Why can demand for a good fall when income increases?

[Read the post](https://qianzhaoli949-afk.github.io/qianzhao-website/blog/posts/post1/Untitled.html) · [Repository guide](../../../README.md)

## Code, data, and results

| Component | Location and purpose |
| --- | --- |
| Article and code | [Untitled.qmd](Untitled.qmd): explanation and the executable R plotting chunk |
| Data | The `income` and `noodle_packages` vectors defined inside that chunk |
| Results | The downward-sloping illustrative plot embedded in the rendered article |
| Rendered page | `docs/blog/posts/post1/Untitled.html`, relative to the repository root |

The six observations are hypothetical teaching data. There is no external dataset to download and no separate data directory is needed. The chart illustrates a definition; it does not estimate real-world noodle demand.

## Reproduce

1. Install R and Quarto. In the R console, install the rendering packages once:

   ```r
   install.packages(c("knitr", "rmarkdown"))
   ```

2. Open a terminal in the repository root (the folder containing `_quarto.yml`) and run:

   ```sh
   quarto render blog/posts/post1/Untitled.qmd
   ```

3. Open `docs/blog/posts/post1/Untitled.html`. Rendering executes the R chunk and recreates its figure. The plotted data should show noodle packages decreasing from 18 to 5 as monthly income increases from 1,500 to 6,500.

For the plot alone, run the R chunk in `Untitled.qmd` in RStudio. It uses base R and requires no additional plotting package. Edit the `.qmd`, not the generated HTML. Rendering updates generated files in `docs/`.

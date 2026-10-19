# Quantum Chaos to Thermodynamics

An original Quarto course companion to D'Alessio, Kafri, Polkovnikov, and Rigol, *Advances in Physics* **65**, 239–362 (2016). For senior undergraduates and beginning graduate students.

**Read:** https://xing-phys.github.io/quantum-chaos-to-thermodynamics/

**PDF:** https://xing-phys.github.io/quantum-chaos-to-thermodynamics/quantum-chaos-to-thermodynamics.pdf

The book covers the review's numbered topics and appendices with original exposition, derivations, exercises, and reproducible illustrations. See `coverage.qmd` for the complete mapping. This is an independent teaching draft, not an authorized edition of the review.

## Build

Requires Quarto 1.10.18 and a TeX installation (LuaLaTeX; Quarto TinyTeX is sufficient).

```sh
quarto render
python3 scripts/check_book.py
quarto preview --no-browser
```

HTML and the combined PDF are written to `_site/`. The preview command prints its local URL. Root `.qmd` files are chapters; `assets/` holds APS citation style, bibliographies, matching PDF/MathJax macros, and light/dark themes.

Numerical figures and raw data are checked in, so reading and building do not require Julia. Regenerate with Julia 1.12:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. scripts/generate_figures.jl
```

The script uses a fixed seed, checks numerical consistency, and writes raw data to `data/` and PNG/PDF figures to `figs/`. Full environment versions are in `Manifest.toml`.

## Publishing

GitHub Pages serves the `gh-pages` branch. The GitHub Actions workflow renders HTML/PDF, validates links and references, then publishes on changes to `main`. It can also be run manually. For a local publication:

```sh
quarto render
python3 scripts/check_book.py
quarto publish gh-pages --no-render --no-prompt --no-browser
```

## Rights and attribution

Original text, figures, and data: CC BY 4.0; code: MIT. See `LICENSE.md`. External publications retain their own rights. No third-party figures or review PDF are redistributed. The book was developed with AI assistance; assess its scientific claims through the derivations, assumptions, sources, and reproducible calculations.

# Replication lab – the housing-audit case

## **What is this?**

A ready-to-run replication exercise for the course "Applied Replication for Data Skills". You reproduce one of the reanalyses from the Multi100 project, whose results were recently published in *Nature* (Aczel et al. 2026), and test the robustness of a published claim: that emails to public housing authorities signed with Hispanic names were less likely to be answered with a greeting by name than emails signed with white names (Einstein and Glick 2017). You are analyst no. 6, working with the public data of the original study and the choices that the five Multi100 analysts faced.

The report you build is `index.qmd`. It renders out of the box: the data ship inside `data/`, so your very first `quarto preview` works with no edits and no network.

------------------------------------------------------------------------

## Setting up the workspace

This workspace is a plain folder, with no version control and no account to sign in to. You download it, unzip it, and work inside it.

1.  **Download the workspace.** On the GitHub page of the template, click the green **Code** button, then **Download ZIP** – or use the direct link `https://github.com/CodeMoreh/replication-lab-housing/archive/refs/heads/main.zip`. Save it somewhere you own (Desktop or Documents).

2.  **Unzip it.** Extract the ZIP to a real folder (on Windows, "Extract All" – do not work inside the compressed preview). You will get a folder called `replication-lab-housing-main` containing `index.qmd`, `data/`, `R/`, and this file.

3.  **Open the folder in your IDE.** In Positron or VS Code, **File → Open Folder…** and pick the unzipped folder; in RStudio, open `replication-lab-housing.Rproj`, which sits inside it. (Positron is the one that the walkthrough uses on the shared screen; any of the three works for every step.)

4.  **Restore the packages.** This workspace has no lockfile that pins package versions. Instead, `R/check_setup.R` checks what is installed and lists what is missing. In the R console:

    ``` r
    source("R/check_setup.R")
    ```

    It prints an `[OK]` / `[FAIL]` line per check (R version, Quarto, the six required packages, the data files, and a fit of the reference specification, which must come out at −19.97 percentage points). If any packages are missing, it prints the one line that installs them. Run that line, then re-run the check.

5.  **Open the report and preview it.** Open `index.qmd`, then in a terminal inside your IDE:

    ``` sh
    quarto preview
    ```

    The skeleton report opens in a browser. That is your starting point – now work through the tasks inside `index.qmd`. `working_script.R` holds the same steps as a plain script, for working in the console.

------------------------------------------------------------------------

## A note on version control

This folder is kept free of git for the session. There is nothing to commit or push and no account to set up, so everyone in the class can get to the analysis in minutes, whatever their machine.

The workspace *came from* a GitHub repository (`CodeMoreh/replication-lab-housing`), and putting your own work under version control – and publishing the rendered report to a live URL – is the natural take-home step. The course site has a self-study companion module that goes through it click by click: **Git and GitHub self-study** at <https://codemoreh.github.io/applied-replication-housing/companion/git-github.html>. The `.github/` and `.devcontainer/` folders already in this workspace set up that route once the folder is a repository again. You can ignore them for the session.

------------------------------------------------------------------------

## What you will do today

The tasks in `index.qmd` map to the learning objectives of the day:

- **The three Rs.** Distinguish reproducibility, robustness and replicability, and say why the distinction matters. *(Task 1)*
- **Meet the data.** Count the 1,014 emails, the replies and the greetings by name, by the name that signed each email. *(Task 2)*
- **State the estimand and encode it in a causal graph.** Write the target quantity, then finish the graph with `dagitty` and ask which paths open when the comparison is made among replies only. *(Task 2, continued)*
- **Reproduce the recorded result.** From the public file of the original authors, reproduce **$\chi^2$ = 14.265**, the value recorded for analyst 8PTRZ in the Multi100 dataset, and find out why it is not 14.95. *(Task 3)*
- **Work the specification menu.** Fit alternative specifications with `try_spec()`, compare them, and submit the one you would defend to the class chart with `submit_exploration()`, where it is labelled exploratory. *(Task 4)*
- **Preregister, then fit.** Complete the preregistration block, then fit it with `run_spec()` and place it among the 64 specifications of the curve. *(Task 5)*
- **Locate yourself in the multiverse.** Submit your result with `report_result()` and find your marks among the others on the class chart by the tag that both submission functions print. *(Task 5, continued)*
- **Go further.** Sweep a whole decision, place the five analysts on the curve, compare the test of the model with a randomisation test, or read the SCORE replication with new data. *(Going further)*

------------------------------------------------------------------------

## Links

- **Course site:** https://codemoreh.github.io/applied-replication-housing/
- **Submit your results:** `submit_exploration()` in Task 4 and `report_result()` in Task 5 each print a link to a pre-filled Google Form; open it and press **Send**, and the result appears on the live multiverse chart at https://codemoreh.github.io/applied-replication-housing/cases/housing/multiverse.html
- **Take-home git/GitHub path:** https://codemoreh.github.io/applied-replication-housing/companion/git-github.html
- **The data:** the replication package of the original study on Harvard Dataverse, https://doi.org/10.7910/DVN/1HOVTU (CC0).
- **The five Multi100 analyses:** the Multi100 component of the paper on the OSF, https://osf.io/38rsh/, with one sub-component per analyst (8PTRZ at https://osf.io/j8wvh/).

------------------------------------------------------------------------

## Notes for the repository maintainer

This workspace is published as the "Use this template" repository `CodeMoreh/replication-lab-housing`. Two folders serve the take-home and publishing route:

- `.devcontainer/devcontainer.json` – a Codespaces / dev-container image (R + Quarto + the package list) so the repository can be opened and rendered in the cloud with no local install.
- `.github/workflows/publish.yml` – renders the report and publishes it to GitHub Pages on every push, once **Settings → Pages → Source** is set to **"GitHub Actions"**. It installs R and re-runs the chunks, so the edits of a participant show up.

Neither is needed for the zip route used in class. Keep `data/` in step with the `cases/housing/data/` folder of the course repository. `housing_audit.csv` is what the report and the helpers read, and `audit_original.csv` is the public file of the original authors, on which Task 3 runs. `spec_curve.csv` is the curve of 64 specifications, against which `R/spec_tools.R` checks and places every live fit, and `menu_options.csv` gives the reason for every option that is not on the curve. `analysts5.csv` and `reference_marks.csv` record the five Multi100 analyses and the reference marks of the curve. The codebooks beside them describe every column. The estimator in `R/spec_tools.R` is a verbatim copy of `R/housing/_tools.R` in the course repository, which builds the curve; the configuration block at the top of that file holds the ID and entry codes of the results Form.

------------------------------------------------------------------------

## References

Aczel, B., Szaszi, B., Clelland, H. T., et al. (2026). Investigating the analytical robustness of the social and behavioural sciences. *Nature*, 652(8108), 135–142.

Einstein, K. L., & Glick, D. M. (2017). Does race affect access to government services? An experiment exploring street-level bureaucrats and access to public housing. *American Journal of Political Science*, 61(1), 100–116.

------------------------------------------------------------------------

*Code is MIT-licensed; prose and figures are CC BY 4.0, and the data are CC0 – see `LICENSE`.*

# emp-project

This repository tracks:
- `gss/` data files
- `o*net/` data files

The CPS extract is intentionally **not versioned** because GitHub blocks files larger than 100 MB.

## Reproducing the local CPS setup

1. Create (or keep) a local `cps/` directory in the project root.
2. Get CPS data from **IPUMS CPS**:
   - Go to `https://cps.ipums.org/`.
   - Create/sign in to an account.
   - Select CPS samples and variables for your project.
   - Submit an extract request and download the raw data when ready.
3. Place the raw data file at:
   - `cps/cps_00001.dat`
4. Keep this file local only (it is ignored by `.gitignore`).

### Notes

- Current local CPS file size in this setup is approximately 3.3 GB.
- If you regenerate the extract with a different filename, either rename it to `cps_00001.dat` or update your analysis scripts accordingly.
- IPUMS usually provides codebooks and syntax files with the extract; keep those locally as needed for reproducibility.

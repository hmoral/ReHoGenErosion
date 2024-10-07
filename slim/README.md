The `direct_run_launch_allv3.sh` script launches the simulations in four steps:

1. **Step 1**: Quickly generate input files for step #2.
2. **Step 2**: `msprime` run to obtain a mutated tree with neutral mutations, avoiding long burn-in within SLiM.
3. **Step 3**: `SLiM` code to translate the tree sequence file into standard SLiM output, avoiding slow SLiM running times with tree-seq recording on in step #4.
4. **Step 4**: `SLiM` simulation that reads the burn-in file, adds deleterious mutations, and performs the demographic changes as described in the paper.

For a quick test, run the following code:

```
./direct_run_launch_allv3.sh out_test testFile 200 1000 20 1000 1 1e-08 0.5 3 1000 100 10 1
```

For obtaining quick plots of the test run, launch the following R script:

```
Rscript ReHo_metapop_plot.R PATH 1000
```

# AP_Combi_Opti

Julia package required: Gurobi, Random, JuMP, Plots, Printf, JSON, DataFrames, XLSX, Distributions

The APC is composed of several functions named APC_L(), APC_MILP(), APC_random(), APC_IP(), main(), time_MILP_model() and time_APCL_model().

Assuming that the standard distribution of Julia v1.10 is properly installed and configured on the targeted computer (see https://julialang.org/), codes can be executed with this ways:


The instances files should be contained in a folder named "data" for the code to run without modifying the julia files.
The instances should be in csv files, where each column is an instance ordered in descending order (i.e. r0 should be at the top and r_n at the bottom)

From the command-line of the Julia REPL; type:

        - include("APC.jl")

Then,
        - main()

If you execute the program main(), the APC-MILP formulation is resolved on small instance for p belong to [1, n/5, n/2, n], choosing randomly.

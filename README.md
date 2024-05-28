# AP_Combi_Opti

Julia package required: Gurobi, Random, JuMP

The APC-MILP is composed of one main function named APC().

Assuming that the standard distribution of Julia v1.10 is properly installed and configured on the targeted computer (see https://julialang.org/), codes can be executed with this ways:

From the command-line of the Julia REPL; type:

        - include("APC-MILP.jl")

Then,
        - APC()

The main program execute the APC-MILP formulation for p belong to [1, n/5, n/2, n].

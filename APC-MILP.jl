#using JuMP, Gurobi, JSON, DataFrames, XLSX, Distributions, Random
using Gurobi, Random, JuMP

solver = Gurobi.Optimizer; 

Random.seed!(123)

function generateParameters(n)
    r = rand(Uniform(0,1),10);
    r0 = 0
    mu = rand(Uniform(0,1),10);
    mu0 = 0
    return mu0, mu, r0, r
end

# =============================================================
# MILP model ==================================================
# =============================================================

function APC()

    # Model: Here we define the object containing the model
    model = Model(solver)

    # Parameters: 
    n = 10
    p = [1,n/5,n/2,n]
    mu0, mu, r0, r = generateParameters(n)

    # Variables ----------------------------------------------- 
    # This is one way of declaring variables.
    @variable(model, y[i in 1:n] >= 0) # ou alors @variable(model, y[i in 0:n] >= 0)
    @variable(model, y0 >= 0)          # et mettre y[0] partout à la place de y0
    @variable(model, z[i in 1:n] , Bin)

    # Second way.
    # In the rest of the code, this implies changing y0 to y[0].

    # @variable(model, y[i in 0:n] >= 0) 
    # @variable(model, y0 >= 0)          
    # @variable(model, z[i in 1:n] , Bin)

    # Constraints ---------------------------------------------
    @constraint(model, C1, y0 + sum(y[i] for i in 1:n) == 1)
    @constraint(model, C2[i in 1:n], y[i] <= y0*exp(mu[i]))
    @constraint(model, C3[i in 1:n], y[i] <= z[i])
    @constraint(model, C4, sum(z[i] for i in 1:n) <= p[rand(1:4)])

    # Objective function --------------------------------------
    @objective(model, Max, (r0*y0) + sum(r[i]*y[i] for i in 1:n))

    #@show model
    @show p
    optimize!(model)

    status = termination_status(model)

    if status == MOI.OPTIMAL
        println("The problem is solved to optimality")
        println("z = ",objective_value(model)) # print the optimal value
        #println("x = ",value.(x))
        #println("y = ",value.(y))
    elseif status == MOI.INFEASIBLE
        println("The problem is impossible")
    elseif status == MOI.INFEASIBLE_OR_UNBOUNDED
        println("The problem is unbounded")
    end
end


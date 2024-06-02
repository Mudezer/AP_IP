using Gurobi, Random, JuMP, Plots, Printf, JSON, DataFrames, XLSX, Distributions

include("parser.jl")
include("greedy.jl")

solver = Gurobi.Optimizer; 

Random.seed!(123)

# =============================================================
# AP-L model ==================================================
# =============================================================

function APC_L(n,p,r,r0,mu,m0) 

    # Model: Here we define the object containing the model
    model = Model(solver)

    # Variables ----------------------------------------------- 
    # This is one way of declaring variables.
    @variable(model, y[i in 1:n] >= 0) 
    @variable(model, y0 >= 0)          
    @variable(model, z[i in 1:n] , Bin)

    # Second way.
    # In the rest of the code, this implies changing y0 to y[0].

    # @variable(model, y[i in 0:n] >= 0) 
    # @variable(model, y0 >= 0)          
    # @variable(model, z[i in 1:n] , Bin)

    # Constraints ---------------------------------------------
    @constraint(model, C1, y0 + sum(y[i] for i in 1:n) == 1)
    @constraint(model, C2[i in 1:n], y[i] <= y0*exp(mu[i]))

    # Objective function --------------------------------------
    @objective(model, Max, (r0*y0) + sum(r[i]*y[i] for i in 1:n))

    optimize!(model)

    status = termination_status(model)

    if status == MOI.OPTIMAL
        println("The problem is solved to optimality")
        println("z = ",objective_value(model))
    elseif status == MOI.INFEASIBLE
        println("The problem is impossible")
    elseif status == MOI.INFEASIBLE_OR_UNBOUNDED
        println("The problem is unbounded")
    end

    return objective_value(model)
end

# =============================================================
# APC-MILP model ==============================================
# =============================================================

function APC_MILP(n,p,r,r0,mu,m0) 

    # Model: Here we define the object containing the model
    model = Model(solver)

    # Variables ----------------------------------------------- 
    # This is one way of declaring variables.
    @variable(model, y[i in 1:n] >= 0) 
    @variable(model, y0 >= 0)          
    @variable(model, z[i in 1:n] , Bin)

    # Constraints ---------------------------------------------
    @constraint(model, C1, y0 + sum(y[i] for i in 1:n) == 1)
    @constraint(model, C2[i in 1:n], y[i] <= y0*exp(mu[i]))
    @constraint(model, C3[i in 1:n], y[i] <= z[i])
    @constraint(model, C4, sum(z[i] for i in 1:n) <= p)

    # Objective function --------------------------------------
    @objective(model, Max, (r0*y0) + sum(r[i]*y[i] for i in 1:n))

    optimize!(model)

    status = termination_status(model)

    if status == MOI.OPTIMAL
        println("The problem is solved to optimality")
        println("z = ",objective_value(model)) 
    elseif status == MOI.INFEASIBLE
        println("The problem is impossible")
    elseif status == MOI.INFEASIBLE_OR_UNBOUNDED
        println("The problem is unbounded")
    end

    return objective_value(model)
end

# =============================================================
# RANDOM model ================================================
# =============================================================

Random.seed!(123)

function generateParameters(n)
    r = rand(Uniform(0,1),1000000); 
    r0 = 0
    mu = rand(Uniform(0,1),1000000);
    mu0 = 0
    return mu0, mu, r0, r
end

function APC_random()

    # Model: Here we define the object containing the model
    model = Model(solver)

    # Parameters: 
    n = 1000000
    p = [1,n/5,n/2,n]
    mu0, mu, r0, r = generateParameters(n)

    # Variables ----------------------------------------------- 
    # This is one way of declaring variables.
    @variable(model, y[i in 1:n] >= 0) 
    @variable(model, y0 >= 0)          
    @variable(model, z[i in 1:n] , Bin)

    # Constraints ---------------------------------------------
    @constraint(model, C1, y0 + sum(y[i] for i in 1:n) == 1)
    @constraint(model, C2[i in 1:n], y[i] <= y0*exp(mu[i]))
    @constraint(model, C3[i in 1:n], y[i] <= z[i])
    @constraint(model, C4, sum(z[i] for i in 1:n) <= p[rand(1:4)])

    # Objective function --------------------------------------
    @objective(model, Max, (r0*y0) + sum(r[i]*y[i] for i in 1:n))

    optimize!(model)

    status = termination_status(model)

    if status == MOI.OPTIMAL
        println("The problem is solved to optimality")
        println("z = ",objective_value(model)) 
    elseif status == MOI.INFEASIBLE
        println("The problem is impossible")
    elseif status == MOI.INFEASIBLE_OR_UNBOUNDED
        println("The problem is unbounded")
    end

    return objective_value(model)
end

# =============================================================
# APC-IP ======================================================
# =============================================================


function APC_IP(lambda, mu, r)

    # Define the model with Gurobi optimizer
    model = Model(Gurobi.Optimizer)
    
    # Variables ----------------------------------------------- 
    @variable(model, x[1:n], Bin)  

    # Constraints ---------------------------------------------
    @constraint(model, sum(x[i] for i in 1:n) <= p)

    # Objective function --------------------------------------
    @objective(model, Max, (r0 + sum(x[i] * r[i] * exp(mu[i]) for i in 1:n)) / (1 + sum(x[i] * exp(mu[i]) for i in 1:n)))
    
    # Solve the model
    optimize!(model)

    # Return the optimal value of the objective and the values of x
    return objective_value(model), value.(x)
end

# =============================================================
# MAIN ========================================================
# =============================================================

function main()
    n = 10 
    p = n / 2  

    m0 = 0
    number = 100

    plot_z = Float64[]  # Array to store objective values
    plot_i = Int64[]    # Array to store iteration numbers

    i = 1
    z = 0

    while i <= number
        println("i: $i")
        r0, r, mu = call_parser(i)  # Parse input data
        getTime = time()
        
        z = APC_MILP(n, p, r, r0, mu, m0)  # Solve the APC_MILP model
        timeConsumed = round(time() - getTime, digits=6)
        @printf(" | time (s): %10.6f", timeConsumed)

        # Store the objective value and iteration number
        push!(plot_z, z)   
        push!(plot_i, i)   

        i += 1
    end

    # Plot the results
    plot(plot_i, plot_z, label="Primal Bound", xlabel="Iteration", ylabel="Objective Value")  
end

function time_MILP_model()
    getTime = time()
    z = APC_random()
    timeConsumed = round(time() - getTime, digits=6)

    # Print the results
    println("\n The optimal value is ", z, " and the time is ", timeConsumed)

end

function time_APCL_model()
    n = 10
    p = [1,n/5,n/2,n]
    mu0, mu, r0, r = generateParameters(n)

    getTime = time()
    z = APC_L(n,p,r,r0,mu,m0)
    timeConsumed = round(time() - getTime, digits=6)

    # Print the results
    println("\n The optimal value is ", z, " and the time is ", timeConsumed)

end
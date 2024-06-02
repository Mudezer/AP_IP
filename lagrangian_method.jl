using JuMP, Plots, DataFrames, Gurobi

include("parser.jl")

# Definition of the model
function APC_IP_model(n, r0, r, mu, p, lambda)

    model = Model(Gurobi.Optimizer)

    @variable(model, x[1:n], Bin)
    @variable(model, y0 >= 0)
    @variable(model, y[i in 1:n] >= 0) 
    @variable(model, z[1:n], Bin)

    for i in 1:n
        @constraint(model, y[i] <= y0 * exp(mu[i]) * z[i])
    end
    @constraint(model, [i in 1:n], y[i] <= y0*exp(mu[i]))

    @objective(model, Max, y0(r0+lambda*p) + sum( (r[i]*exp(mu[i])-lambda) / exp(mu[i])*y[i] for i in 1:n) )

    return model
end

# Lagrangian algorithm to solve the primal problem
function lagrangian_method(n, p, r, mu, r0, lambda)

    model = APC_IP_model(n, r0, r, mu, p, lambda)
    optimize!(model)
    return objective_value(model)
end

# Binary search for the dual
function binary_search(epsilon, r0, p, mu, r)
    lambda_min     = 0.0
    r1             = maximum(r)
    lambda_max     = r1 / p
    best_lambda    = lambda_min
    best_objective = -Inf

    while (lambda_max - lambda_min) > epsilon

        lambda_middle = (lambda_min + lambda_max) / 2
        objective = lagrangian_method(length(r), p, r, mu, r0, lambda_middle)
        
        if objective > best_objective
            best_objective = objective
            best_lambda    = lambda_middle
        end

        if objective < lagrangian_method(length(r), p, r, mu, r0, lambda_min)[1]
            lambda_max = lambda_middle
        else
            lambda_min = lambda_middle
        end
    end

    return best_lambda, best_objective
end

# Main function
function main()

    # Input data
    n  = 5000     
    p  = n / 2  

    r0, r, mu = call_parser(10)

    # Parameters for binary search
    epsilon = 1e-4

    # Initialize lists to store the best primal and dual bounds
    primal_bounds = Float64[]
    dual_bounds   = Float64[]

    # Search for the best value of lambda
    best_lambda, best_objective = binary_search(epsilon, r0, p, mu, r)

    println("Best lambda: ", best_lambda)
    println("Best objective value: ", best_objective)

    i= 0
    lambda = 0

    # Plot the primal and dual bounds
    while i < 10 
        objective = lagrangian_method(n, p, r, mu, r0, lambda)
        push!(primal_bounds, objective)
        push!(dual_bounds, best_objective)

        if (i == 10)
            break
        end
        i += 1
        lambda += epsilon
    end

    plot(0:epsilon:best_lambda, primal_bounds, label="Primal Bound", xlabel="Lambda", ylabel="Objective Value")
    #plot!(0:epsilon:best_lambda, dual_bounds, label="Dual Bound", linestyle=:dash)
end
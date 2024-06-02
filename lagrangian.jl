# Lagrangian method for the part 4.3.4 of the report

using JuMP, Plots, DataFrames, Gurobi, Statistics

include("parser.jl")

# Definition of the model APL lambda
function APL_lambda_model(n, r0, r, mu, p, lambda)

    model = Model(Gurobi.Optimizer)

    @variable(model, y0 >= 0)
    @variable(model, y[i in 1:n] >= 0) 

    for i in 1:n
        @constraint(model, y[i] <= y0 * exp(mu[i]))
    end

    @constraint(model, y0 + sum( y[i] for i in 1:n) == 1)

    @objective(model, Max, y0*(r0+lambda*p) + sum( (r[i]*exp(mu[i])-lambda) / exp(mu[i])*y[i] for i in 1:n) )

    return model
end

# Solving APL_lambda_model using Gurobi
function lagrangian_method(n, p, r, mu, r0, lambda)

    model = APL_lambda_model(n, r0, r, mu, p, lambda)
    optimize!(model)
    return objective_value(model)
end


# Binary search using APL_lambda_model 
function binary_search(epsilon, r0, p, mu, r)
    lambda_inf     = 0.0
    r1             = maximum(r)
    lambda_sup     = maximum([0, r1 - r0] ./ p)
    best_lambda    = lambda_inf
    best_value = -Inf

    # stopping criteria
    while (lambda_sup - lambda_inf) > epsilon

        lambda_middle = (lambda_inf + lambda_sup) / 2
        value = lagrangian_method(length(r), p, r, mu, r0, lambda_middle)
        
        # update best value
        if value > best_value
            best_value = value
            best_lambda    = lambda_middle
        end

        if value < lagrangian_method(length(r), p, r, mu, r0, lambda_inf)[1]
            lambda_sup = lambda_middle
        else
            lambda_inf = lambda_middle
        end
    end

    return best_lambda, best_value
end

# Greedy for lagrangian using r(lambda) and r0(lambda) form as describe in the repert
function greedy_lagrange(r0, r, mu, lambda, p)
    n = length(r)
    # define as in the report in section 4.3.1
    r0lambda = r0 - lambda * p
    rlambda = [(r[i] * exp(mu[i]) - lambda)/exp(mu[i]) for i in 1:n]
    I = collect(1:n)
    S_opt = []
    value_opt = 0

    for k in I
        # Compute the values of π
        π0_k = r0lambda + sum(exp(mu[j]) * rlambda[j] for j in 1:k) / (1 + sum(exp(mu[j]) for j in 1:k))
        π_k = [rlambda[i] - (r0lambda + sum(exp(mu[j]) * rlambda[j] for j in 1:k)) / (1 + sum(exp(mu[j]) for j in 1:k)) for i in 1:k]
        
        # Check the feasibility constraints
        if all(π0_k >= r[i] - π_k[i] * exp(mu[i]) for i in 1:k) && π0_k - sum(π_k[i] * exp(mu[i]) for i in 1:k) >= r0lambda
            value = r0lambda + sum(exp(mu[i]) * rlambda[i] for i in 1:k)
            # Update the best solution if necessary
            if value_opt < value
                value_opt = value
                S_opt = collect(1:k)
            end
        end
    end

    return S_opt, value_opt
end

# lagrangian dual problem with dichotomie
function lagrangian_dual(r0, r, mu, p, epsilon)
    # bounds of lambda as precised in the report
    lambda_inf = 0
    lambda_sup = maximum([0, maximum(r) - r0] ./ p)
    # Init
    best_value = -Inf
    best_lambda = lambda_inf
    pbounds = []
    dbounds = []

    # stopping criteria
    while lambda_sup - lambda_inf > epsilon
        # cut the search interval in half
        lambda = (lambda_inf + lambda_sup) / 2
        # solve the pb with the new lambda
        S_opt, value_opt = greedy_lagrange(r0, r, mu, lambda, p)
        #value_opt = lagrangian_method(n, p, r, mu, r0, lambda) # using Gurobi to solve the pb, no limited in the number of items
        # update bounds
        push!(pbounds, value_opt)
        push!(dbounds, lambda)
        
        # number of item criteria
        if length(S_opt) <= p
            best_value = value_opt
            best_lambda = lambda
            lambda_sup = lambda
        else
            lambda_inf = lambda
        end
    end

    return best_value, best_lambda, pbounds, dbounds
end

epsilon = 0.01

#############################


# Instance
r0, r, mu = call_parser(1)

# Parameters
epsilon = 0.01
n=length(r)
p=n/2

# Resolution
best_value, best_lambda, pbounds, dbounds = lagrangian_dual(r0, r, mu, p, epsilon)

# Print
println("Meilleure valeur duale : ", best_value)
println("Meilleure lambda : ", best_lambda)

#@show(pbounds)
#@show(dbounds)
# Plot
plot(pbounds, label="Primal Bound", xlabel="Iteration", ylabel="Value")
plot!(dbounds, label="Dual Bound", xlabel="Iteration", ylabel="Value")

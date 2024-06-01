
using JuMP, Plots, DataFrames, Gurobi

include("parser.jl")


function solve_primal(lambda,mu,r) #modele AP-L

    model = Model(Gurobi.Optimizer)
    
    @variable(model, x[1:n], Bin)  
    @variable(model, y0 >= 0)
    @variable(model, y[1:n] >= 0)
    @variable(model, z[1:n], Bin)


    @constraint(model, y0 * (1 + sum(x[i] * exp(mu[i]) for i in 1:n)) <= 1)

    for i in 1:n
        @constraint(model, y[i] * (1 + sum(x[j] * exp(mu[j]) for j in 1:n)) <= x[i] * exp(mu[i]))
    end

    @constraint(model, y0 + sum(y[i] for i in 1:n) == 1)

    for i in 1:n
        @constraint(model, [i in 1:n], y[i] <= y0* exp(mu[i]))
    end

    #@constraint(model, sum(z) <= p)  
    @constraint(model, [i in 1:n], y[i] <= z[i])  



    @objective(model, Max, r[1] * y0 + sum(r[i] * y[i] for i in 1:n) - lambda * sum(z[i] for i in 1:n))

    optimize!(model)

    return objective_value(model), value.(x), value(y0), value.(y), value.(z)
end

# Utilisation de la recherche binaire pour obtenir le dual
function binary_search_dual(epsilon, r0, p,mu,r)
    lambda_min = 0.0
    r1=r[end]
    lambda_max = r1/p #(r1 - r0) / p
    tolerance = epsilon
    best_lambda = lambda_min
    best_objective = -Inf

    @show lambda_max, r1, p

    while (lambda_max - lambda_min) > tolerance

        #@show (lambda_max - lambda_min) > tolerance

        lambda_middle = (lambda_min + lambda_max) / 2

        current_objective, _, _, _ = solve_primal(lambda_middle,mu,r)
        
        if current_objective >= best_objective
            best_objective = current_objective
            best_lambda = lambda_middle
        end

        if current_objective < solve_primal(lambda_min,mu,r)[1]
            lambda_max = lambda_middle
        else
            lambda_min = lambda_middle
        end


        #@show lambda_max, lambda_min
        #@show (lambda_max - lambda_min) > tolerance
        #@show lambda_middle 
        #@show current_objective > best_objective, current_objective, best_objective
        #@show current_objective < solve_primal(lambda_min)[1], solve_primal(lambda_min)[1] 
        #println("------------------------------------\n\n")
    end

    #@assert false "stop"

    return best_lambda, best_objective
end

function main_lagrange_relaxation()
        
    # Paramètres pour la recherche binaire
    epsilon = 1e-4
    r0 = 0
    r1 = r[end]

    @show r0, r1
    @show r, mu

    best_lambda, best_objective = binary_search_dual(epsilon, r0, p,mu,r)
    println("Meilleure lambda: ", best_lambda)
    println("Meilleure valeur objective: ", best_objective)

    # Traces primales et duales
    lambdas = 0:epsilon:best_lambda  # Modifier ici
    primal_bounds = []
    dual_bounds = []

    for lambda in lambdas
        objective, _, _, _ = solve_primal(lambda,mu,r)
        push!(primal_bounds, objective)
        push!(dual_bounds, best_objective)
    end

    @show primal_bounds, dual_bounds

    #plot(lambdas, primal_bounds, label="Primal Bound", xlabel="Lambda", ylabel="Objective Value")
    #plot!(lambdas, dual_bounds, label="Dual Bound", linestyle=:dash)

end


function main()

    # Données d'entrée
    n = 10   # Nombre de produits
    p = n/2  # Capacité maximale
    number = 10
    epsilon = 1e-4
    primal_bounds = []
    dual_bounds = []

    i::Int64 = 1

    while i <= number
        println("i: $i")
        r0, r, mu = call_parser(i)
        @show r
        r1 = r[end]
        best_lambda, best_objective = binary_search_dual(epsilon, r0, p,mu,r)

        println("------------------------Pour i qui vaut $i ------------------------")
        println("Meilleure lambda: ", best_lambda)
        println("Meilleure valeur objective: ", best_objective)

        lambdas = 0:epsilon:best_lambda
        println("lambdassss: ", lambdas)

        for lambda in lambdas
            objective, _, _, _ = solve_primal(lambda,mu,r)
            push!(primal_bounds, objective)
            push!(dual_bounds, best_objective)
        end
        println("primal_bounds: ", primal_bounds)
        println("dual_bounds: ", dual_bounds)
        println("------------------------------------------------------------------------")

        i += 1
    end
    plot(primal_bounds, dual_bounds, label="Primal Bound", xlabel="Lambda", ylabel="Objective Value")
    plot!(lambdas, dual_bounds, label="Dual Bound", linestyle=:dash)

end

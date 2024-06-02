using JuMP, Plots, DataFrames, Gurobi

include("parser.jl")

# Définition du modèle 
function APC_IP_model(n, r0, r, mu, p, lambda)
    model = Model(Gurobi.Optimizer)

    @variable(model, x[1:n], Bin)
    @variable(model, y0 >= 0)
    @constraint(model, sum(x[i] for i in 1:n) <= p)
    println("helLLLLooo")
    @objective(model, Max, (r0 + sum(x[i] * r[i] * exp(mu[i]) for i in 1:n)) / (1 + sum(x[i] * exp(mu[i]) for i in 1:n)) - lambda * (sum(x[i] for i in 1:n) - p))
    
    return model
end

# Algorithme du Lagrangien pour résoudre le problème primal
function solve_lagrangian(n, p, r, mu, r0, lambda)
    model = APC_IP_model(n, r0, r, mu, p, lambda)

    optimize!(model)
    return objective_value(model), value.(x)
end

# Recherche binaire pour le dual
function binary_search_dual(epsilon, r0, p, mu, r)
    lambda_min     = 0.0
    r1             = maximum(r)
    lambda_max     = r1 / p
    best_lambda    = lambda_min
    best_objective = -Inf

    while (lambda_max - lambda_min) > epsilon

        lambda_middle      = (lambda_min + lambda_max) / 2
        objective, useless = solve_lagrangian(length(r), p, r, mu, r0, lambda_middle)
        
        if objective > best_objective
            best_objective = objective
            best_lambda    = lambda_middle
        end

        if objective < solve_lagrangian(length(r), p, r, mu, r0, lambda_min)[1]
            lambda_max = lambda_middle
        else
            lambda_min = lambda_middle
        end
    end

    return best_lambda, best_objective
end

# Fonction principale
function main()

    # Données d'entrée
    n  = 10     
    p  = n / 2  

    r0, r, mu = call_parser(1)

    # Paramètres pour la recherche binaire
    epsilon = 1e-4

    # Initialisation des listes pour stocker les meilleures bornes primales et duales
    primal_bounds = Float64[]
    dual_bounds = Float64[]

    # Recherche de la meilleure valeur de lambda
    best_lambda, best_objective = binary_search_dual(epsilon, r0, p, mu, r)

    println("Meilleure lambda: ", best_lambda)
    println("Meilleure valeur objective: ", best_objective)

    # Tracé des bornes primales et duales
    for lambda in 0:epsilon:best_lambda
        objective, useless = solve_lagrangian(n, p, r, mu, r0, lambda)
        push!(primal_bounds, objective)
        push!(dual_bounds, best_objective)
    end

    plot(0:epsilon:best_lambda, primal_bounds, label="Primal Bound", xlabel="Lambda", ylabel="Objective Value")
    plot!(0:epsilon:best_lambda, dual_bounds, label="Dual Bound", linestyle=:dash)
end

# Appel de la fonction principale
main()

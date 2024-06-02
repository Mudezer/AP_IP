using JuMP, Plots, DataFrames, Gurobi

include("parser.jl")

# Définition du modèle 
function APC_IP_model(n, r0, r, mu, p, lambda)

    model = Model(Gurobi.Optimizer)

    println("yo")

    @variable(model, x[1:n], Bin)
    @variable(model, y0 >= 0)
    @variable(model, y[i in 1:n] >= 0) 
    @variable(model, z[1:n], Bin)

    println("yo")

    for i in 1:n
        @constraint(model, y[i] <= y0 * exp(mu[i]) * z[i])
    end
    @constraint(model, [i in 1:n], y[i] <= y0*exp(mu[i]))
    #@constraint(model, sum(x[i] for i in 1:n) <= p)
    println("helLLLLooo")

    for t in 1:n
        println("\n\n")
        println("r[$t]: ",r[t] )
        println("\n\n")
    end

    #@objective(model, Max, (r0 + sum(x[i] * r[i] * exp(mu[i]) for i in 1:n)) / (1 + sum(x[i] * exp(mu[i]) for i in 1:n)) - lambda * (sum(x[i] for i in 1:n) - p))
    @objective(model, Max, (r0*y0) + sum(r[i]*y[i]*z[i] for i in 1:n)- lambda * (sum(x[i] for i in 1:n) - p))
    println("helLLLLooo")

    return model
end

# Algorithme du Lagrangien pour résoudre le problème primal
function lagrangian_method(n, p, r, mu, r0, lambda)
    println("yo")
    model = APC_IP_model(n, r0, r, mu, p, lambda)

    println("helLLLLooo2")
    optimize!(model)
    println("helLLLLooo4")
    @show objective_value(model)
    @show r, length(r)
    return objective_value(model)
end

# Recherche binaire pour le dual
function binary_search(epsilon, r0, p, mu, r)
    lambda_min     = 0.0
    r1             = maximum(r)
    lambda_max     = r1 / p
    best_lambda    = lambda_min
    best_objective = -Inf

    @show r

    while (lambda_max - lambda_min) > epsilon

        lambda_middle      = (lambda_min + lambda_max) / 2
        @show r
        @show length(r)
        objective = lagrangian_method(length(r), p, r, mu, r0, lambda_middle)
        
        println("helLLLLooo3")
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

# Fonction principale
function main()

    # Données d'entrée
    n  = 10     
    p  = n / 2  

    r0, r, mu = call_parser(10)

    # Paramètres pour la recherche binaire
    epsilon = 1e-4

    # Initialisation des listes pour stocker les meilleures bornes primales et duales
    primal_bounds = Float64[]
    dual_bounds   = Float64[]

    # Recherche de la meilleure valeur de lambda
    best_lambda, best_objective = binary_search(epsilon, r0, p, mu, r)

    println("Meilleure lambda: ", best_lambda)
    println("Meilleure valeur objective: ", best_objective)

    i= 0
    lambda = 0

    # Tracé des bornes primales et duales
    while i <10#lambda <= best_lambda
        objective = lagrangian_method(n, p, r, mu, r0, lambda)
        push!(primal_bounds, objective)
        push!(dual_bounds, best_objective)

        if (i==10)
            break
        end
        i+=1
        lambda += epsilon
        @show lambda
        @show best_lambda
    end

    plot(0:epsilon:best_lambda, primal_bounds, label="Primal Bound", xlabel="Lambda", ylabel="Objective Value")
    #plot!(0:epsilon:best_lambda, dual_bounds, label="Dual Bound", linestyle=:dash)
end

#=
function main2()
    # Données d'entrée
    n = 10     
    p = n / 2  

    r0, r, mu = call_parser(10)

    # Paramètres pour la recherche binaire
    epsilon = 1e-4

    # Initialisation des listes pour stocker les meilleures bornes primales et duales
    primal_bounds = Float64[]
    dual_bounds   = Float64[]

    # Recherche de la meilleure valeur de lambda
    best_lambda, best_objective = binary_search(epsilon, r0, p, mu, r)

    println("Meilleure lambda: ", best_lambda)
    println("Meilleure valeur objective: ", best_objective)

    # Tracé des bornes primales et duales
    for lambda in 0:epsilon:best_lambda
        objective = lagrangian_method(n, p, r, mu, r0, lambda)
        push!(primal_bounds, objective)
        push!(dual_bounds, best_objective)
    end

    plot(0:epsilon:best_lambda, primal_bounds, label="Primal Bound", xlabel="Lambda", ylabel="Objective Value")
    plot!(0:epsilon:best_lambda, dual_bounds, label="Dual Bound", linestyle=:dash)
end
=#
# Appel de la fonction principale
main()

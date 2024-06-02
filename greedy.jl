

function greedy_AP(r0, r, μ)
    n = length(r)
    I = collect(1:n)
    S_opt = []
    value_opt = 0.0

    for k in I
        # Calculer les valeurs de π
        π0_k = r0 + sum(exp(μ[j]) * r[j] for j in 1:k) / (1 + sum(exp(μ[j]) for j in 1:k))
        π_k = [r[i] - (r0 + sum(exp(μ[j]) * r[j] for j in 1:k)) / (1 + sum(exp(μ[j]) for j in 1:k)) for i in 1:k]

        # Vérifier les contraintes de faisabilité
        if all(π0_k >= r[i] - π_k[i] * exp(μ[i]) for i in 1:k) && π0_k - sum(π_k[i] * exp(μ[i]) for i in 1:k) >= r0
            value = r0 + sum(exp(μ[i]) * r[i] for i in 1:k)
            # Mettre à jour la meilleure solution si nécessaire
            if value_opt < value
                value_opt = value
                S_opt = collect(1:k)
            end
        end
    end

    return S_opt, value_opt
end

# Exemple d'utilisation
r0 = 0.0
r = [1.0, 2.0, 3.0]
μ = [0.1, 0.2, 0.3]

S_opt, value_opt = greedy_AP(r0, r, μ)

println("Meilleure sélection de produits : ", S_opt)
println("Valeur optimale : ", value_opt)
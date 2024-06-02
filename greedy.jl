# Greedy Algorithm from the part 3.2.3 of the report

function greedy_AP(r0, r, μ)
    n = length(r)
    I = collect(1:n)
    S_opt = []
    value_opt = 0.0

    for k in I
        # Compute the values of π
        π0_k = r0 + sum(exp(μ[j]) * r[j] for j in 1:k) / (1 + sum(exp(μ[j]) for j in 1:k))
        π_k = [r[i] - (r0 + sum(exp(μ[j]) * r[j] for j in 1:k)) / (1 + sum(exp(μ[j]) for j in 1:k)) for i in 1:k]

        # Check the feasibility constraints
        if all(π0_k >= r[i] - π_k[i] * exp(μ[i]) for i in 1:k) && π0_k - sum(π_k[i] * exp(μ[i]) for i in 1:k) >= r0
            value = r0 + sum(exp(μ[i]) * r[i] for i in 1:k)
            # Update the best solution if necessary
            if value_opt < value
                value_opt = value
                S_opt = collect(1:k)
            end
        end
    end

    return S_opt, value_opt
end

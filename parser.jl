using CSV
using DataFrames

function parser_file(filename,i)
    # Read the CSV file with ";" as separators
    df = CSV.read(filename, DataFrame; delim=';')

    r_vectors = df[:, i]

    return 0, r_vectors
end


function call_parser()
    filename_r = "data/small-r.csv"
    filename_mu = "data/small-mu.csv"

    r_vectors_r = []
    r_vectors_mu = []

    for i in 1:1
        println("------------- $i -------------")
        r0_r, r_vectors_r = parser_file(filename_r,i)
        #
        r0_mu, r_vectors_mu = parser_file(filename_mu,i)
        #
        #println("r_vectors pour $i: ", r_vectors_r, "\nr_vectors mu", r_vectors_mu)
        println("\n")
    end

    return 0, r_vectors_r, r_vectors_mu
end
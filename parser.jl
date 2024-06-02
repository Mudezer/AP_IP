using CSV
using DataFrames

function parser_file(filename, i)
    # Read the CSV file with ";" as separators and load it into a DataFrame
    df = CSV.read(filename, DataFrame; delim=';')

    # Extract the i-th column from the DataFrame
    r_vectors = df[:, i]

    return 0, r_vectors
end


function call_parser(i)
    # Define the filenames for the data files
    filename_r = "data/medium-r.csv"
    filename_mu = "data/medium-mu.csv"

    # Initialize empty arrays to store the vectors
    r_vectors_r = []
    r_vectors_mu = []
    
    # Parse the r file and extract the i-th column
    r0_r, r_vectors_r = parser_file(filename_r, i)
    # Parse the mu file and extract the i-th column
    r0_mu, r_vectors_mu = parser_file(filename_mu, i)

    return 0, r_vectors_r, r_vectors_mu
end
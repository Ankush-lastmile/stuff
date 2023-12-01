#!/bin/bash

# Check if file path argument is provided
if [[ -z "$1" ]]; then
    echo "Error: No file path argument provided"
    echo "Usage: ./diff_notebook_to_parent.sh /path/to/file"
    exit 1
fi

# The $1 variable holds the first argument passed to the script
file_path="$1"

# Create a temporary file 
temp_file=$(mktemp)

# define a function to cleanup the temp file, used later in this script
function cleanup {
    rm "$temp_file"
    printf "\nTemporary file $temp_file has been removed."
}

# Verify if file exists and readable
if [[ -r "$file_path" ]]; then
    # Read contents of file and write to temp file
    printf "\n\nWriting ipynb to temp file"
    cp "$file_path" "$temp_file"

    # Store current hash id
    current_hash=$(sl id)

    # if current hash has a '+', then it has uncommitted changes.  Echo warning and quit
    if [[ $current_hash == *"+"* ]]; then
        echo "Warning: You have uncommitted changes.  Please commit or stash your changes before running this script."
        cleanup
        exit 1
    fi

    # Goto parent commit
    printf "\n\nnavigating to parent commit"
    sl prev    

    # Run nbdiff-web as a background process. -web creates a rich diff of the notebooks
    printf "\nOpening the notebook diff in your browser\n"
    nbdiff-web "$file_path" "$temp_file" > /dev/null & 

    # Get the process ID of the background process (nnbdiff-web)
    nbdiff_pid=$!
    
    # Wait for 1 second
    sleep 1

    # Kill the nbdiff-web process. It doesn't need to stay alive to view the webpage
    printf "\n\n Terminating nbdiff process"
    kill $nbdiff_pid

    # Reset state, go back to current commit
    printf "\n\nResetting Sapling State\n"
    sl goto $current_hash


    # Cleanup the temp file
    cleanup
    # echo temp_path
else 
    echo "Error: File does not exist or is not readable"
fi
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

# Verify if file exists and readable
if [[ -r "$file_path" ]]; then
    # Read contents of file and write to temp file
    cat "$file_path" > "$temp_file"

    # Store current hash id
    current_hash=$(sl id)

    # Goto parent commit
    sl prev

    # Run nbdiff-web as a background process. -web creates a rich diff of the notebooks

    echo "Opening the notebook diff in your browser"

    nbdiff-web "$file_path" "$file_path" &

    # Get the process ID of the background process (nnbdiff-web)
    nbdiff_pid=$!
    
    # Wait for 1 second
    sleep 1

    # Kill the nbdiff-web process. It doesn't need to stay alive to view the webpage
    kill $nbdiff_pid

    # Reset state, go back to current commit
    sl goto $current_hash


    # Cleanup the temp file
    rm "$temp_file"
    echo "Temporary file $temp_file has been removed."
else 
    echo "Error: File does not exist or is not readable"
fi
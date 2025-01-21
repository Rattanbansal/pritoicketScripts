import os
import pandas as pd
import shutil
import re

# Function to get a list of all PDF files from the given directory and subdirectories
def get_pdf_files(root_dir):
    pdf_files = []
    for dirpath, _, filenames in os.walk(root_dir):
        for file in filenames:
            if file.endswith('.pdf'):
                pdf_files.append(os.path.join(dirpath, file))
    return pdf_files

# Function to check if the file name matches any part of the name in the CSV
def is_matched(file_name, csv_names):
    # Normalize the file name: remove special characters, convert to lowercase
    normalized_file_name = re.sub(r'[^a-zA-Z0-9]', ' ', os.path.splitext(os.path.basename(file_name))[0].lower())
    # Check if any part of any name from the CSV matches the file name
    for full_name in csv_names:
        # Normalize the name: split into parts (first, last, etc.), convert to lowercase
        name_parts = full_name.lower().split()
        if any(part in normalized_file_name for part in name_parts):  # If any part matches, return True
            return True
    return False

# Main function to find and copy unmatched PDFs
def find_and_copy_unmatched_pdfs(root_dir, csv_path, output_dir):
    # Load CSV and extract unique names
    csv_data = pd.read_csv(csv_path)

    # Ensure the 'Name' column exists
    if 'Name' not in csv_data.columns:
        raise KeyError(f"The column 'Name' does not exist. Available columns: {', '.join(csv_data.columns)}")

    # Get unique names from the CSV
    csv_names = csv_data['Name'].drop_duplicates().astype(str).tolist()

    # Get all PDF files
    pdf_files = get_pdf_files(root_dir)

    # Ensure the output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Copy unmatched files
    for pdf_file in pdf_files:
        if not is_matched(pdf_file, csv_names):  # Copy if no match is found
            shutil.copy(pdf_file, output_dir)
            print(f"Copied: {pdf_file}")

# Specify paths
root_directory = 'pdffiles'  # Replace with the actual root directory
csv_file_path = 'merged.csv'  # Replace with the actual CSV file path
output_directory = 'unmatched_resumes'  # Replace with the folder to store unmatched resumes

# Run the script
find_and_copy_unmatched_pdfs(root_directory, csv_file_path, output_directory)

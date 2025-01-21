from docx import Document
import PyPDF2
import os
import re
import csv

def extract_text_from_docx(file_path):
    """Extract text from a DOCX file."""
    try:
        doc = Document(file_path)
        return "\n".join([p.text for p in doc.paragraphs])
    except Exception as e:
        print(f"Error reading DOCX file {file_path}: {e}")
        return ""

def extract_text_from_pdf(file_path):
    """Extract text from a PDF file."""
    text = ""
    try:
        with open(file_path, 'rb') as file:
            pdf_reader = PyPDF2.PdfReader(file)
            for page in pdf_reader.pages:
                text += page.extract_text()
    except Exception as e:
        print(f"Error reading PDF file {file_path}: {e}")
    return text

def extract_name(text):
    """Extract name from text."""
    lines = text.splitlines()
    for line in lines:
        if line.strip().lower().startswith("name") or re.match(r"^[A-Z][a-z]+\s[A-Z][a-z]+$", line.strip()):
            return line.strip()
    return "Not mentioned"

def extract_mobile_number(text):
    """Extract mobile number using regex."""
    match = re.search(r'\+?\d{10,13}', text)
    return match.group(0) if match else "Not mentioned"

def extract_experience(text):
    """Extract years of experience from text."""
    match = re.search(r'(\d+(\.\d+)?)\s+years? of experience', text, re.IGNORECASE)
    if match:
        return match.group(1)
    # Fallback: search for "years" in context
    for line in text.splitlines():
        if "years" in line.lower() and re.search(r'\d+(\.\d+)?', line):
            return re.search(r'\d+(\.\d+)?', line).group(0)
    return "Not mentioned"

def extract_projects(text):
    """Extract project details from text."""
    projects_section = re.search(r'(Projects|Portfolio)(.*?)(Education|Experience|$)', text, re.DOTALL | re.IGNORECASE)
    return projects_section.group(2).strip() if projects_section else "Not mentioned"

def process_resumes(input_folder, output_file):
    """Process resumes and save extracted data to CSV."""
    output_data = []

    for file_name in os.listdir(input_folder):
        file_path = os.path.join(input_folder, file_name)

        if file_name.endswith(".docx"):
            text = extract_text_from_docx(file_path)
        elif file_name.endswith(".pdf"):
            text = extract_text_from_pdf(file_path)
        else:
            continue

        # Extract fields
        data = {
            "Name": extract_name(text),
            "Mobile Number": extract_mobile_number(text),
            "Experience (Years)": extract_experience(text),
            "Projects": extract_projects(text)
        }
        output_data.append(data)

    # Write to CSV
    with open(output_file, 'w', newline='', encoding='utf-8') as file:
        writer = csv.DictWriter(file, fieldnames=["Name", "Mobile Number", "Experience (Years)", "Projects"])
        writer.writeheader()
        writer.writerows(output_data)

# Paths for input and output
input_folder = "./resumes"  # Replace with your folder path
output_file = "Corrected_Resume_Data.csv"  # Replace with desired output file name

# Process resumes
process_resumes(input_folder, output_file)

print(f"Data extraction completed. Results saved to {output_file}.")

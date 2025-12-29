import os

def calculate_folder_size(folder_path):
    """Calculate the total size of a folder, including all subfolders and files."""
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(folder_path):
        for filename in filenames:
            file_path = os.path.join(dirpath, filename)
            # Make sure the path is a file (not a symbolic link, for example)
            if os.path.isfile(file_path):
                total_size += os.path.getsize(file_path)
    return total_size

def format_size(size_bytes):
    """Convert bytes to a human-readable format."""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024:
            return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024
    return f"{size_bytes:.2f} PB"

def process_folders(main_folder):
    """Process each folder inside the main folder and calculate total size."""
    total_size = 0
    list_folders = []
    # Loop through all folders inside the main folder
    for folder_name in os.listdir(main_folder):
        folder_path = os.path.join(main_folder, folder_name)
        list_folders.append(folder_name)
        if os.path.isdir(folder_path):  # Make sure it's a folder
            print(f"Processing folder: {folder_path}")
            folder_size = calculate_folder_size(folder_path)
            print(f"Size of folder {folder_name}: {format_size(folder_size)}")
            total_size += folder_size
    print({"num od foldes":len(list_folders)})

    # Return the total size of all folders combined
    return total_size

# Path to your scraping folder data
main_folder = "media/scraping_folder_data"  # Make sure this is correct

# Get the total size of the scraping_folder_data
total_size = process_folders(main_folder)

# Print the total size of the entire main folder
print(f"Total size of '{main_folder}': {format_size(total_size)}")

import subprocess
import getpass

# Function to execute shell commands
def run_command(command):
    try:
        result = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(result.stdout.decode())
    except subprocess.CalledProcessError as e:
        print(f"Error occurred: {e.stderr.decode()}")

# Step 1: Create MySQL user without a password
def create_mysql_user():
    # Prompt for MySQL root password
    root_pwd = getpass.getpass(prompt="Enter MySQL root password: ")
    
    # Command to create a user without a password
    command = f"mysql -u root -p{root_pwd} -e \"CREATE USER 'root'@'localhost' IDENTIFIED BY '';\""
    run_command(command)

# Step 2: Create the ekri database
def create_database():
    root_pwd = getpass.getpass(prompt="Enter MySQL root password: ")
    command = f"mysql -u root -p{root_pwd} -e \"CREATE DATABASE ekri;\""
    run_command(command)

# Step 3: Execute SQL source files
def execute_sources():
    root_pwd = getpass.getpass(prompt="Enter MySQL root password: ")
    sql_files = [
        "/list_tables/states.sql",
        "/list_tables/delegations.sql",
        "/list_tables/jurisdictions.sql",
        "/list_tables/types.sql"
    ]
    
    # Create the ekri database and run source commands
    for sql_file in sql_files:
        command = f"mysql -u root -p{root_pwd} ekri -e \"SOURCE {sql_file};\""
        run_command(command)

# Step 4: Run Django migrations
def run_django_migrations():
    print("Running Django migrations...")
    command = "python3 manage.py migrate"
    run_command(command)

# Step 4: Execute SQL source types file
def execute_sources():
    root_pwd = getpass.getpass(prompt="Enter MySQL root password: ")
    sql_types_file = "/list_tables/types.sql"
    
    # Create the ekri database and run source commands
    command = f"mysql -u root -p{root_pwd} ekri -e \"SOURCE {sql_types_file};\""
    run_command(command)

def main():
    create_mysql_user()
    create_database()
    execute_sources()
    run_django_migrations()

if __name__ == "__main__":
    main()

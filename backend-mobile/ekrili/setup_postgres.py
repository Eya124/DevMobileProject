import subprocess

POSTGRES_CONTAINER = "app-db-container"   # <-- change
POSTGRES_USER = "postgres"                  # <-- change if needed
POSTGRES_DB = "postgres"                        # <-- target database

# Execute shell commands
def run_command(command):
    try:
        result = subprocess.run(
            command,
            shell=True,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        print(result.stdout.decode())
    except subprocess.CalledProcessError as e:
        print("❌ Error:", e.stderr.decode())


# Step 1: Create PostgreSQL user
def create_postgres_user():
    print("Creating PostgreSQL user...")

    command = (
        f"docker exec -i {POSTGRES_CONTAINER} "
        f"psql -U {POSTGRES_USER} -c \"CREATE USER ekri_user WITH PASSWORD 'ekri_pwd';\""
    )
    run_command(command)


# Step 2: Create database
def create_database():
    print(f"Creating database {POSTGRES_DB}...")

    command = (
        f"docker exec -i {POSTGRES_CONTAINER} "
        f"psql -U {POSTGRES_USER} -c \"CREATE DATABASE {POSTGRES_DB};\""
    )
    run_command(command)


# Step 3: Run SQL files (PostgreSQL equivalent of MySQL SOURCE)
def execute_sql_files():
    print("Executing SQL files in PostgreSQL...")

    sql_files = [
        "./list_tables/states.sql",
        "./list_tables/delegations.sql",
        "./list_tables/jurisdictions.sql",
        "./list_tables/types.sql"
    ]

    for sql_file in sql_files:
        command = (
            f"docker exec -i {POSTGRES_CONTAINER} "
            f"psql -U {POSTGRES_USER} -d {POSTGRES_DB} -f /list_tables/{sql_file.split('/')[-1]}"
        )
        run_command(command)


# Step 4: Django migrations
# def run_django_migrations():
#     print("Running Django migrations...")
#     run_command("python3 manage.py migrate")
#     run_command("python3 manage.py migrate")


def main():
    # create_postgres_user()
    # create_database()
    execute_sql_files()
    # run_django_migrations()


if __name__ == "__main__":
    main()

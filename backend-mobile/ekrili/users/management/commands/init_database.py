import os
import subprocess
from django.core.management.base import BaseCommand
from django.conf import settings

class Command(BaseCommand):
    help = 'Initializes the ekri database and imports SQL files'

    def handle(self, *args, **options):
        base_dir = os.getcwd()  # Or use settings.BASE_DIR
        sql_path = os.path.join(base_dir, 'list_tables')

        # Step 1: Set root password using native password plugin
        self.stdout.write('🔐 Setting MySQL root password...')
        self.run_sudo_mysql([
            "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'ekri';",
            "FLUSH PRIVILEGES;"
        ])

        # Step 2: Create and use ekri database
        self.stdout.write('🛠️ Creating and preparing database...')
        self.run_mysql_command("CREATE DATABASE IF NOT EXISTS ekri;")
        self.run_mysql_command("USE ekri;")

        # Step 3: Source SQL files
        for sql_file in ['states.sql', 'delegations.sql', 'jurisdictions.sql']:
            self.run_source_file(sql_path, sql_file)

        # Step 4: Change to base_dir and run Django migrations
        self.stdout.write('⚙️ Running Django migrations...')
        os.chdir(base_dir)  # Change directory to base_dir before running migrations
        subprocess.call(['python3', 'manage.py', 'migrate'])

        # Step 5: Final SQL import
        self.run_source_file(sql_path, 'types.sql')

        self.stdout.write(self.style.SUCCESS('✅ Database setup complete.'))

    def run_sudo_mysql(self, sql_commands):
        full_command = " ".join(sql_commands)
        subprocess.call([
            'sudo', 'mysql', '-e', full_command
        ])

    def run_mysql_command(self, command):
        subprocess.call([
            'mysql', '-u', 'root', '-pekri',
            '-e', command
        ])

    def run_source_file(self, path, file_name):
        full_path = os.path.join(path, file_name)
        if os.path.exists(full_path):
            subprocess.call([
                'mysql', '-u', 'root', '-pekri',
                '-e', f"USE ekri; SOURCE {full_path};"
            ])
        else:
            self.stderr.write(self.style.ERROR(f"{file_name} not found in {path}."))

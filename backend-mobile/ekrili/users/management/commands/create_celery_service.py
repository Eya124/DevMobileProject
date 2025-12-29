import os
import subprocess
from django.core.management.base import BaseCommand

class Command(BaseCommand):
    help = 'Create Celery Worker systemd service file'

    def add_arguments(self, parser):
        # Optional argument
        parser.add_argument('-u', '--user', type=str, help='Define a user')
        
    def handle(self, *args, **kwargs):
        # Get the path to the celery executable using 'which celery'
        try:
            user = kwargs['user']
            celery_path = subprocess.check_output(['which', 'celery']).decode('utf-8').strip()
            if not celery_path:
                raise ValueError("Celery executable not found. Please make sure it's installed and available in the PATH.")
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error finding celery executable: {str(e)}"))
            return

        # Define the content of the systemd service file
        service_content = f"""
[Unit]
Description=Celery Worker Service
After=network.target

[Service]
Type=simple
User={user}
Group={user}
WorkingDirectory={os.path.join(os.getcwd())}
ExecStart={celery_path} -A ekrili worker --loglevel=info
Restart=always
RestartSec=10s

# Optional: Environment variables (Django settings, etc.)
Environment=DJANGO_SETTINGS_MODULE=ekrili.settings
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
"""

        # Attempt to write the service file to the system directory
        service_file_path = '/etc/systemd/system/celery_worker.service'
        user_service_path = os.path.join(os.getcwd(), 'celery_worker.service')

        try:
            # Try writing to the system directory first
            with open(service_file_path, 'w') as f:
                f.write(service_content)
            self.stdout.write(self.style.SUCCESS(f"Service file created at {service_file_path}"))
        except PermissionError:
            # If permission is denied, save to a user-writable location and inform the user
            self.stdout.write(self.style.WARNING(f"Permission denied while writing to {service_file_path}."))
            self.stdout.write(self.style.SUCCESS(f"Service file created at {user_service_path}."))
            with open(user_service_path, 'w') as f:
                f.write(service_content)

            os.system(f"sudo mv {user_service_path} {service_file_path}")
            self.stdout.write(self.style.SUCCESS(f"sudo mv {user_service_path} {service_file_path}"))
            os.system("sudo systemctl daemon-reload")
            self.stdout.write(self.style.SUCCESS(f"sudo systemctl daemon-reload"))
            os.system("sudo systemctl start celery_worker.service")
            self.stdout.write(self.style.SUCCESS(f"sudo systemctl start celery_worker.service"))
            os.system("sudo systemctl enable celery_worker.service")
            self.stdout.write(self.style.SUCCESS(f"sudo systemctl enable celery_worker.service"))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error writing service file: {str(e)}"))

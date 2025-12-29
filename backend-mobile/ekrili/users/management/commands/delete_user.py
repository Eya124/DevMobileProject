from django.core.management.base import BaseCommand
from django.contrib.auth.hashers import make_password
from users.models import User
from django.db import IntegrityError

class Command(BaseCommand):
    
    def add_arguments(self, parser):
        # Optional argument
        parser.add_argument('-e', '--email', type=str, help='Define a super admin email')
        
    def handle(self, *args, **kwargs):
        # Your code to add data to the database here
        try:
            email = kwargs['email']
            if not email:
                self.stdout.write(self.style.ERROR('email must be required.'))
                return
            try:
                admin  = User.objects.filter(email=email)
                if admin:
                    admin.delete()
                    self.stdout.write(self.style.SUCCESS('Super admin deleted successfully.'))
                else:
                    self.stdout.write(self.style.ERROR('email not found.'))
                    return
            except IntegrityError as e:
                self.stdout.write(self.style.ERROR(f'Error: {str(e)}'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'An unexpected error occurred: {str(e)}'))
        except IntegrityError as e:
            return "Error: " + str(e)

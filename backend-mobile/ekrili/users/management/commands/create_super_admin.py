from django.core.management.base import BaseCommand
from django.contrib.auth.hashers import make_password
from users.models import User
from django.db import IntegrityError

class Command(BaseCommand):
    
    def add_arguments(self, parser):
        # Optional argument
        parser.add_argument('-e', '--email', type=str, help='Define a super admin email')
        parser.add_argument('-p', '--pw', type=str, help='Define a super admin password')
        parser.add_argument('-fn','--first_name', type=str, help='Define a first name')
        parser.add_argument('-ln','--last_name', type=str, help='Define a last name')
        
    def handle(self, *args, **kwargs):
        # Your code to add data to the database here
        try:
            email = kwargs['email']
            pw = kwargs['pw']
            if not email or not pw:
                self.stdout.write(self.style.ERROR('All fields (username, email, password) are required.'))
                return
            try:
                email = f'{email}'
                password = f'{pw}'
                first_name = kwargs.get('first_name')
                last_name = kwargs.get('last_name')
     
                admin  = User.objects.create(last_name=last_name,first_name=first_name, password=make_password(password),email=email,is_admin=True,is_verified=True)
                admin.save()
                self.stdout.write(self.style.SUCCESS('Super admin added successfully.'))
            except IntegrityError as e:
                self.stdout.write(self.style.ERROR(f'Error: {str(e)}'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'An unexpected error occurred: {str(e)}'))
        except IntegrityError as e:
            return "Error: " + str(e)

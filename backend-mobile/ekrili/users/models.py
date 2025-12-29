from django.db import models
from django.contrib.auth.models import (AbstractBaseUser, BaseUserManager)
# Create your models here.

class MyUserManager(BaseUserManager):
    def create_user(self, email, password=None):
        """
        Creates and saves a User with the given email and password.
        """
        if not email:
            raise ValueError('Users must have an email address')

        user = self.model(
            email=self.normalize_email(email),  # Pass the email here
        )

        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None):
        """
        Creates and saves a superuser with the given username and password.
        """
        user = self.create_user(email, password=password)
        user.is_admin = True
        user.save(using=self._db)
        return user


class User(AbstractBaseUser):
    last_name = models.CharField(max_length=100, null=True, blank=True)
    first_name = models.CharField(max_length=100, null=True, blank=True)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=20, null=True, blank=True)
    state = models.ForeignKey('annonces.State', on_delete=models.CASCADE, null=True, blank=True)
    delegation = models.ForeignKey('annonces.Delegation', on_delete=models.CASCADE, null=True, blank=True)
    jurisdiction = models.ForeignKey('annonces.Jurisdiction', on_delete=models.CASCADE, null=True, blank=True)
    password = models.CharField(max_length=800, null=True)
    is_verified = models.BooleanField(default=False)
    recommanted = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)
    is_admin = models.BooleanField(default=False)
    token_last_expired = models.DateTimeField(null=True)
    objects = MyUserManager()
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []

    class Meta:
        db_table = 'users'
        
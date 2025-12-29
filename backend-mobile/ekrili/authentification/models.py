from django.db import models
from users.models import User

# Create your models here.

class VerificationCode(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.CASCADE)
    code = models.CharField(max_length=8)
    expiration_time = models.DateTimeField()
    class Meta:
        db_table = 'verification_code'
from django.db import models
from users.models import User
# Create your models here.

class Historique(models.Model):
    search_query = models.CharField(max_length=100)
    date_of_search = models.DateField(null=True, blank=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    class Meta:
        db_table = 'historiques'
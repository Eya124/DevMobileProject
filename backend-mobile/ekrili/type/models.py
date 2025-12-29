from django.db import models

# Create your models here.
class Type(models.Model):
    name = models.CharField(max_length=100)
    class Meta:
        db_table = 'types'
    def __str__(self):
        return self.name
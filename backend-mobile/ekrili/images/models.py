from django.db import models
from annonces.models import Annonce
# Create your models here.

class Image(models.Model):
    image_url = models.CharField(max_length=800)
    annonce = models.ForeignKey(Annonce, on_delete=models.CASCADE, related_name='images')  # Correct related_name
    
    class Meta:
        db_table = 'images'

from django.utils import timezone
from django.db import models
 
from annonces.models import Annonce
from authentification.authentication import User
 
# Create your models here.
class Feedback(models.Model):
    label=models.CharField(max_length=200, blank=True)
    rating=models.IntegerField(null=True, blank=True)
    likes=models.IntegerField(null=True, blank=True)
    dislikes=models.IntegerField(null=True, blank=True)
    comment=models.CharField(max_length=200, blank=True)
    user_id=models.IntegerField(null=True, blank=True,default=0)
    annonce = models.ForeignKey(Annonce, on_delete=models.CASCADE)
    # Created and updated timestamps
    created_at = models.DateTimeField(default=timezone.now, editable=False)
    updated_at = models.DateTimeField(default=timezone.now,editable=False)
 
    def save(self, *args, **kwargs):
        if not self.id:
            self.created_at = timezone.now()
        self.updated_at = timezone.now()
        super(Feedback, self).save(*args, **kwargs)
 
    class Meta:
        db_table = 'feedback'
 
 
from django.utils import timezone
from django.db import models

from annonces.models import Annonce
from authentification.authentication import User

# Create your models here.
class Chatbot(models.Model):
    question=models.TextField(blank=True)
    answer=models.TextField(blank=True)
    created_at = models.DateTimeField(default=timezone.now, editable=False)
    created_by = models.IntegerField(null=True)

    def save(self, *args, **kwargs):
        # request = kwargs.pop('request', None) 
        # current_user = request.user if request and request.user.is_authenticated else None
        # if not self.id:
        #     self.created_at = timezone.now()
        #     self.created_by = current_user
        #     self.updated_by = current_user
        self.updated_at = timezone.now()
        super(Chatbot, self).save(*args, **kwargs)

    class Meta:
        db_table = 'chatbot'
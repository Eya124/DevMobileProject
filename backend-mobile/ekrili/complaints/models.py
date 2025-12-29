from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from django.conf import settings
class Complaint(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
    )


    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="complaints"
    )
    title = models.CharField(max_length=255)
    Text = models.TextField()
    
    status = models.CharField(max_length=50, default="pending")
    
    reply = models.TextField(null=True, blank=True)
    replied_at = models.DateTimeField(null=True, blank=True)
    # replied_by = models.ForeignKey(
    #     settings.AUTH_USER_MODEL,
    #     null=True,
    #     blank=True,
    #     on_delete=models.SET_NULL,
    #     related_name="admin_replies"
    # )
    
    
    created_at = models.DateTimeField(default=timezone.now, editable=False)
    updated_at = models.DateTimeField(default=timezone.now,editable=False)

    def save(self, *args, **kwargs):
        if not self.id:
            self.created_at = timezone.now()
        self.updated_at = timezone.now()
        super(Complaint, self).save(*args, **kwargs)

    class Meta:
        db_table = 'complaint'

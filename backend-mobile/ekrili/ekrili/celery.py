from __future__ import absolute_import, unicode_literals
import os
from celery import Celery

# Set the default settings module for the Celery app
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ekrili.settings')

app = Celery('ekrili')

# Load configuration from Django settings
app.config_from_object('django.conf:settings', namespace='CELERY')

# Automatically discover tasks in all apps
app.autodiscover_tasks()

@app.task(bind=True)
def debug_task(self):
    print(f'Request: {self.request!r}')

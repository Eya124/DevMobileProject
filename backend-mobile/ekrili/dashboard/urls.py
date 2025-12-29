from django.urls import path
from . import views

urlpatterns = [
    path('', views.dashboard, name="dashboard"),
    path('users', views.get_filtered_users, name="get_filtered_users"),
]

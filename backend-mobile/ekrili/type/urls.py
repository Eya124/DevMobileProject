from django.urls import path
from . import views

urlpatterns = [
    path('add', views.add_type, name="add_type"),
    path('delete/<int:id>', views.delete_type, name="delete_type"),
    path('update/<int:id>', views.update_type, name="update_type"),
    path('all', views.all_type, name="all_type"),
]

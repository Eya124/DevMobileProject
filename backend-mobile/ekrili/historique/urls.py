from django.urls import path
from . import views

urlpatterns = [
    path('search_query', views.search_query, name="search_query"),
    path('all_search_query', views.all_search_query, name="all_search_query"),
]

from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name="home"),
    # path('dashboard', views.dashboard, name="dashboard"),
    path('annonces/details/<str:filter_value>/', views.annonce_details, name='annonce_details'),
    path('map/', views.map_view, name='map'),
]

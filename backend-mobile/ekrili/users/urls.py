from django.urls import path
from . import views

urlpatterns = [
    path('add', views.add_users, name="add_users"),
    path('profile/<int:id>', views.profile_user, name="profile"),
    path('update/<int:id>', views.update_users, name="update_users"),
    path('delete/<int:id>', views.delete_users, name="delete_users"),
    path('recommanded/<int:id>', views.change_recommanded, name="change_recommanded"),
    path('all', views.all_users, name="all_users"),
    path('forget_password', views.forget_password, name="forget_password"),
    path('verify_code/<int:id>', views.verify_code, name="verify_code"),
    path('change_password/<int:id>', views.change_password, name="change_password"),
]

from django.urls import path
from . import views

urlpatterns = [
    path('signin', views.authentification, name="signin"),
    path('logout', views.logout_view, name="logout"),
    path('signup', views.signup_view, name="signup"),
    path('verify_code/<int:id>', views.verify_code),
    path('resend_verification_code/<int:id>', views.resend_verification_code),
    path('admin-create-user', views.admin_create_user)

]

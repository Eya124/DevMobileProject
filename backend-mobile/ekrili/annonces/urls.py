from django.urls import path
from . import views

urlpatterns = [
    path('add', views.add_annonce, name="add_annonce"),
    path('delete/<int:id>', views.delete_annonce, name="delete_annonce"),
    path('update/<int:id>', views.update_annonce, name="update_annonce"),
    path('update_status/<int:id>', views.update_status, name="update_status"),
    path('all', views.all_annonce, name="all_annonce"),
    path('<int:id>', views.annonce, name="annonce"),
    path('all_annonce_by_user/<int:id>', views.all_annonce_by_user, name="all_annonce_by_user"),
    path('all_annonce_for_map', views.all_annonce_for_map, name="all_annonce_for_map"),
    path('all_states', views.all_states, name="all_states"),
    path('all_types', views.all_types, name="all_types"),
    path('all_delegations_by_state/<int:state_id>', views.all_delegations_by_state, name="all_delegations_by_state"),
    path('all_jurisdictions_by_delegation/<int:delegation_id>', views.all_jurisdictions_by_delegation, name="all_jurisdictions_by_delegation"),
]

from django.urls import path
from .views import   delete_message, get_messages, rag_index, rag_query, update_message

urlpatterns = [
    path("index/",rag_index),
    path("query/", rag_query),
        path("messages/<int:id>/", get_messages),   # READ
    path("message/<int:pk>/", update_message),  # UPDATE
    path("message/delete/<int:pk>/", delete_message),  # DELETE
]

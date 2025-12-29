from django.urls import path
from .views import   get_messages, rag_index, rag_query

urlpatterns = [
    path("index/",rag_index),
    path("query/", rag_query),
    path("all_messages/<int:id>", get_messages),
]

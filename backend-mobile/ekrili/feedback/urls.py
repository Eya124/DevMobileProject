from django.urls import path
from . import views
 
urlpatterns = [
    path('getFeedback', views.getAllFeedback, name="getFeedback"),
    path('getFeedbackById/<int:id>', views.getFeedbackById, name="getFeedbackById"),
    path('addFeedback', views.addFeedback, name="addFeedback"),
    path('updateFeedback/<int:id>', views.updateFeedback, name="updateFeedback"),
    path('addLikeDislike/<int:id>', views.addLikeDislike, name="addLikeDislike"),
    path('deleteFeedback/<int:id>', views.deleteFeedback, name="deleteFeedback"),
    ################################################################
]
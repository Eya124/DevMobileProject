from django.urls import path
from . import views

urlpatterns = [
    path('getFeedback', views.getAllFeedback, name="feedback"),
    path('feedback/<int:id>', views.getFeedbackById, name="feedback"),
    path('feedback', views.addFeedback, name="feedback"),
    path('feedback/<int:id>', views.updateFeedback, name="feedback"),
    path('feedback/<int:id>', views.deleteFeedback, name="deleteFeedback"),
    ################################################################
   
    
  
    
    
    
    

]

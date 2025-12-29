from django.urls import path
from .views import (
    getAllComplaints,
    getComplaintById,
    createComplaint,
    replyToComplaint,
    updateComplaint,
    deleteComplaint,
)

urlpatterns = [
    path('', getAllComplaints, name='get_all_complaints'),
    path('<int:id>/', getComplaintById, name='get_complaint_by_id'),
    path('create/', createComplaint, name='create_complaint'),
    path('update/<int:id>/', updateComplaint, name='update_complaint'),
    path('delete/<int:id>/', deleteComplaint, name='delete_complaint'),
    path('reply/<int:id>/', replyToComplaint, name='reply_to_complaint'),
]

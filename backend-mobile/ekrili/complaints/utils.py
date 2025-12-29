from django.conf import settings
from .models import Complaint
from django.core.paginator import Paginator
from django.core.mail import EmailMultiAlternatives
def get_all_complaints(page_number, property_to_sort, direction):
    queryset = Complaint.objects.all()

    # Sorting
    if property_to_sort:
        if direction == "desc":
            property_to_sort = f"-{property_to_sort}"
        queryset = queryset.order_by(property_to_sort)

    # Pagination
    paginator = Paginator(queryset, 10) 
    if page_number:
        return paginator.get_page(page_number)
    return queryset
def send_reply_email(user,title,text):
    subject = title
    text_message = text
    recipient_list = [user.email]
    from_email = settings.EMAIL_HOST_USER 
    msg = EmailMultiAlternatives(subject, text_message, from_email, recipient_list)
    msg.send()
# from httpx import request
from feedback.models import Feedback
from django.core.paginator import Paginator, EmptyPage
import requests
app_user_url="http://localhost:8091/api/users/"
app_activity_url="http://localhost:8091/api/activities/"
app_center_url="http://localhost:8091/api/camping-centers/"
app_product_url="http://localhost:8091/api/products/"
# token = "Bearer eyJhbGciOiJIUzI1NiJ9.eyJyb2xlcyI6W3siaWQiOjEsIm5hbWUiOiJST0xFX1NVUEVSX0FETUlOIn1dLCJqdGkiOjEsInN1YiI6ImFkbWluQHRlc3QuY29tIiwiaWF0IjoxNzEwOTY3MDY1LCJleHAiOjE3MTIyNjMwNjV9.js_aTusLlxdpjOYly8hc39P1W2tHtjC-6G_-Ucauzq4"
headers = {
# "Authorization": token,
"Content-Type" : "application/json"
}

# custimaization of information to use get
def parse_information(res,list_feedbacks):
    # print(res)

    for i in range(0, len(res)):
        res[i].pop('model')
        id = res[i]['pk']
        res[i].pop('pk')
        res[i]['fields']['id'] = id
     
        
        list_feedbacks.append(res[i]['fields'])
        
    return list_feedbacks

# recuperation of all feedback
def get_all_feedback(page_number, property, direction):
    feedback_list = Feedback.objects.select_related("annonce").all()

    # Sorting
    order_by = property if property else "id"
    if direction == "desc":
        order_by = "-" + order_by

    feedback_list = feedback_list.order_by(order_by)

    # Pagination
    paginator = Paginator(feedback_list, 10)
    page_number = page_number or 1

    try:
        feedback_page = paginator.page(page_number)
    except EmptyPage:
        feedback_page = paginator.page(paginator.num_pages)

    return feedback_page
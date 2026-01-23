from rest_framework.decorators import api_view, permission_classes, authentication_classes
 
from feedback.functions import get_all_feedback, parse_information
from .models import *
from .serializers import *
from django.core import serializers
import json
from django.http import JsonResponse
from django.core import serializers
from django.db.models import Q
from drf_yasg.utils import swagger_auto_schema
# from rest_framework.permissions import
from drf_yasg import openapi
from rest_framework.permissions import AllowAny
@swagger_auto_schema(
    method='GET',
 
)
@api_view(['GET'])
@permission_classes([AllowAny])  
def getAllFeedback(request):
    if (request.method == 'GET'):
        feedbacks=Feedback.objects.all()
        feedbacks_dict = serializers.serialize("json", feedbacks)
        res = json.loads(feedbacks_dict)
        list_feedbacks=[]
        for item in res:
            fields = item['fields']
            user_id = fields.get('user_id')
            user = User.objects.filter(id=user_id).first()
            fields['first_name'] = user.first_name if user else None
            fields['last_name'] = user.last_name if user else None
        list_feedbacks=parse_information(res,list_feedbacks)
    return JsonResponse({"Feedback": list_feedbacks})
@swagger_auto_schema(
    method='GET',
   
)
@api_view(['GET'])
@permission_classes([AllowAny])
def getFeedbackById(request, id):
    if request.method == 'GET':
        try:
            feedback = Feedback.objects.get(id=id)
            feedback_data = serializers.serialize("json", [feedback])
            res = json.loads(feedback_data)
            list_feedbacks=[]
            list_feedbacks=parse_information(res,list_feedbacks)
            return JsonResponse({"Feedback": list_feedbacks[0]})
        except Feedback.DoesNotExist:
            return JsonResponse({"error": "Feedback not found"}, status=404)    
@swagger_auto_schema(
    method='GET',
   
)
 
 
@swagger_auto_schema(
    method='POST',
    request_body=FeedbackSerializer,
    responses={200: 'Created', 400: 'Bad Request'},
    operation_summary="API TO ADD Feedback",
    operation_description="This API add Feedback with their caracteristique in database",
)
@api_view(['POST'])
@permission_classes([AllowAny])
def addFeedback(request):
    if (request.method == 'POST'):
        data = request.data
        feedback_serializer = FeedbackSerializer(data=data)
        if feedback_serializer.is_valid():
                feedback_serializer.save()
                msg="Feedback saved Successfully!"
                status=201
        else:
            msg=feedback_serializer.errors
            status=400
       
    return JsonResponse({"msg:": msg},status=status)  
@swagger_auto_schema(
    method='PUT',
    request_body=FeedbackSerializer,
    responses={200: 'Created', 400: 'Bad Request'},
    operation_summary="API TO UPDATE Feedback",
    operation_description="This API update Feedback with their caracteristique in database",
)
@api_view(['PUT'])
@permission_classes([AllowAny])
def updateFeedback(request,id):
    if (request.method == 'PUT'):
        data = request.data
        if Feedback.objects.filter(id=id).exists():
            feedback_object=Feedback.objects.get(id=id)
            feedback_serializer = FeedbackSerializer(feedback_object,data=data,partial=True)
            if feedback_serializer.is_valid():
                    feedback_serializer.save()
                    msg="Feedback saved Successfully!"
                    status=200
            else:
                msg=feedback_serializer.errors
                status=400
        else:
            msg="Feedback not found!"
            status=404
    return JsonResponse({"msg:": msg},status=status)  
 
question_param = openapi.Schema(
    type=openapi.TYPE_OBJECT,
    properties={
       'type': openapi.Schema(type=openapi.TYPE_STRING, description='type like or dislike'),
    },
    required=['type']
)
@swagger_auto_schema(
    method='put',
    request_body=question_param,
    responses={200: "Feedback reaction updated successfully!"},
)    
@api_view(['PUT'])
@permission_classes([AllowAny])
def addLikeDislike(request,id):
    if (request.method == 'PUT'):
        data = request.data
        type=data.get("type","")
        if type not in ["like","dislike"]:
            return JsonResponse({"msg:": "Invalid type"},status=400)
        if Feedback.objects.filter(id=id).exists():
            feedback_object=Feedback.objects.get(id=id)
            if type=="like":
                feedback_object.likes=(feedback_object.likes or 0)+1
            else:
                feedback_object.dislikes=(feedback_object.dislikes or 0)+1
            feedback_object.save()
            msg="Feedback reaction updated successfully!"
            status=200
        else:
            msg="Feedback not found!"
            status=404
    return JsonResponse({"msg:": msg},status=status)        
@swagger_auto_schema(
    method='DELETE',
    responses={200: 'Created', 400: 'Bad Request'},
    operation_summary="API DELETE FEEDBACK",
    operation_description="This API delete feedback by id ",
)
@api_view(['DELETE'])
@permission_classes([AllowAny])
def deleteFeedback(request,id):
    if (request.method == 'DELETE'):
        if Feedback.objects.filter(id=id).exists():
            feedback_object=Feedback.objects.get(id=id)
            feedback_object.delete()
            msg="Feedback deleted successfully!"
            status=200
        else:
            msg="Feedback not found!"
            status=404
    return JsonResponse({"msg:": msg},status=status)    
 
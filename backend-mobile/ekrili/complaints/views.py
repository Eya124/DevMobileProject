from rest_framework.decorators import api_view, permission_classes
from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from rest_framework.permissions import AllowAny
 
from authentification.authentication import User
from .models import Complaint
from .serializers import ComplaintSerializer
from .utils import get_all_complaints, send_reply_email
import json
from django.utils import timezone
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi
@swagger_auto_schema(
    method='get',
    manual_parameters=[
        openapi.Parameter('page', openapi.IN_QUERY, description="Page number", type=openapi.TYPE_INTEGER),
        openapi.Parameter('sort', openapi.IN_QUERY, description="Field to sort by", type=openapi.TYPE_STRING),
        openapi.Parameter('dir', openapi.IN_QUERY, description="Sort direction (asc/desc)", type=openapi.TYPE_STRING),
    ],
    responses={200: ComplaintSerializer(many=True)}
)
@api_view(['GET'])
@permission_classes([AllowAny])
def getAllComplaints(request):
    page_number = request.query_params.get('page')
    property_to_sort = request.query_params.get('sort')
    direction = request.query_params.get('dir')

    complaints = get_all_complaints(page_number, property_to_sort, direction)
    serializer = ComplaintSerializer(complaints, many=True)

    return JsonResponse({"Complaints": serializer.data}, safe=False)
@api_view(['GET'])
@permission_classes([AllowAny])
def getComplaintById(request, id):
    complaint = get_object_or_404(Complaint, id=id)
    serializer = ComplaintSerializer(complaint)
    return JsonResponse({"Complaint": serializer.data})

@swagger_auto_schema(
    method='post',
    request_body=ComplaintSerializer,
    responses={201: ComplaintSerializer}
)
@api_view(['POST'])
@permission_classes([AllowAny])
def createComplaint(request):
    data = json.loads(request.body)

    serializer = ComplaintSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return JsonResponse({"message": "Complaint created", "Complaint": serializer.data}, status=201)

    return JsonResponse({"errors": serializer.errors}, status=400)
@api_view(['PUT'])
@permission_classes([AllowAny])
def updateComplaint(request, id):
    complaint = get_object_or_404(Complaint, id=id)
    data = json.loads(request.body)

    serializer = ComplaintSerializer(complaint, data=data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return JsonResponse({"message": "Complaint updated", "Complaint": serializer.data})

    return JsonResponse({"errors": serializer.errors}, status=400)
@api_view(['DELETE'])
@permission_classes([AllowAny])
def deleteComplaint(request, id):
    complaint = get_object_or_404(Complaint, id=id)
    complaint.delete()
    return JsonResponse({"message": "Complaint deleted"})

@swagger_auto_schema(
    method='put',
    manual_parameters=[
        openapi.Parameter('id', openapi.IN_PATH, description="Complaint ID", type=openapi.TYPE_INTEGER),
    ],
    request_body=openapi.Schema(
        type=openapi.TYPE_OBJECT,
        required=['reply', 'title', 'user'],
        properties={
            'reply': openapi.Schema(type=openapi.TYPE_STRING, description='Reply text'),
            'title': openapi.Schema(type=openapi.TYPE_STRING, description='Complaint title'),
            'user': openapi.Schema(type=openapi.TYPE_INTEGER, description='User ID to send notification'),
        }
    ),
    responses={200: ComplaintSerializer}
)
@api_view(['PUT'])
@permission_classes([AllowAny])
def replyToComplaint(request, id):
    complaint = get_object_or_404(Complaint, id=id)
    data = json.loads(request.body)

    reply_text = data.get("reply")
    title=data.get('title')
    user=User.objects.get(id=data.get("user"))
    if not reply_text:
        return JsonResponse({"error": "Reply text is required"}, status=400)
    send_reply_email(user,title,reply_text)
    complaint.reply = reply_text
    complaint.replied_at = timezone.now()
    # complaint.replied_by = request.user if request.user.is_authenticated else None
    complaint.status = "replied"
    complaint.save()

    serializer = ComplaintSerializer(complaint)
    return JsonResponse({
        "message": "Reply added successfully",
        "Complaint": serializer.data
    })

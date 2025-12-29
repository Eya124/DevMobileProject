import json
from type.models import Type
from type.serializers import TypeSerializer
from django.http import JsonResponse
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from authentification.authentication import JWTAuthentication
from django.utils import translation
from rest_framework.permissions import AllowAny
# Create your views here.

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def add_type(request):
    """Create a new type"""
    data = json.loads(request.body)
    with translation.override('fr'):
        type_serializer = TypeSerializer(data=data)
        if type_serializer.is_valid():
            type_serializer.save()
            return JsonResponse({'message': "Type crée avec succès"}, status=200)
        else:
            return JsonResponse({'error': type_serializer.errors}, status=400)

@api_view(['DELETE'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def delete_type(request,id):
    type = Type.objects.get(id=id)
    type.delete()
    return JsonResponse({'message': "Type"}, status=200)

@api_view(['PUT'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def update_type(request,id):
    data = request.body
    data = json.loads(data)
    type = Type.objects.get(id=id)
    type_serializer = TypeSerializer(type,data=data)
    if type_serializer.is_valid():
        type_serializer.save()
        return JsonResponse({'data': data}, status=200)
    else:
        return JsonResponse({'error': type_serializer.errors}, status=400)

@api_view(['GET'])
@permission_classes([AllowAny])
def all_type(request):
    """Get all types"""
    types = list(Type.objects.values())
    return JsonResponse({"types": types}, status=200)

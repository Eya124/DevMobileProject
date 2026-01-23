import json
from users.models import User
from django.http import JsonResponse
from users.serializers import SingInSerializer
from django.contrib.auth.hashers import make_password
from django.utils import translation
from django.core import serializers
from .serializers import UpdateUserSerializer
from django.forms.models import model_to_dict
from authentification.models import VerificationCode
from django.utils import timezone
import random
import string
from datetime import timedelta
from django.core.mail import EmailMultiAlternatives
from django.conf import settings
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from authentification.authentication import JWTAuthentication
from django.views.decorators.csrf import csrf_exempt


# Create your views here.
from django.contrib.auth import authenticate

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def change_password_authenticated(request):
    """
    Change password for authenticated user
    """
    user = request.user
    data = json.loads(request.body)

    old_password = data.get('old_password')
    new_password = data.get('new_password')

    if not old_password or not new_password:
        return JsonResponse(
            {"message": "Ancien et nouveau mot de passe requis"},
            status=400
        )

    # ✅ Vérifier ancien mot de passe
    if not user.check_password(old_password):
        return JsonResponse(
            {"message": "Ancien mot de passe incorrect"},
            status=400
        )

    # ✅ Mettre à jour
    user.password = make_password(new_password)
    user.save()

    return JsonResponse(
        {"message": "Mot de passe mis à jour avec succès"},
        status=200
    )

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def add_users(request):
    """Create a new user"""
    # data = request.data
    data = json.loads(request.body)
    data['password'] = make_password(data['password'])
    with translation.override('fr'):
        sing_in_serializer = SingInSerializer(data=data)
        if sing_in_serializer.is_valid():
            sing_in_serializer.save()
            return JsonResponse({'data': data}, status=200)
        else:
            return JsonResponse({'error': sing_in_serializer.errors}, status=400)
@api_view(['POST'])
@permission_classes([AllowAny])
def profile_user(request,id):
    user = User.objects.get(id=id)
    user_data = model_to_dict(user, exclude=["password","last_login","token_last_expired","is_admin","is_active","is_verified"])
    return JsonResponse({'profile': user_data}, status=200)

@api_view(['GET'])
# @authentication_classes([JWTAuthentication])
@permission_classes([AllowAny])
def all_users(request):
    """Get all users"""
    user_list = []
    users = User.objects.all()
    users_json = serializers.serialize('json', users)
    res = json.loads(users_json)
    for i in range(len(res)):
        res[i].pop('model')
        trust_id = res[i]['pk']
        res[i].pop('pk')
        res[i]['fields'].pop('password')
        res[i]['fields'].pop('token_last_expired')
        res[i]['fields']['id'] = trust_id
        user_list.append(res[i]['fields'])
    return JsonResponse({"users": user_list}, status=200)


@api_view(['PUT'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def update_users(request, id):
    """Update a user by id"""
    try:
        # Get the user instance
        user = User.objects.get(id=id)
    except User.DoesNotExist:
        return JsonResponse({"message": "Utilisateur non trouvé."}, status=404)
    with translation.override('fr'):
        # Create the serializer with the data and instance
        serializer = UpdateUserSerializer(user, data=json.loads(request.body), partial=True)

        if serializer.is_valid():
            # Save the updated user
            serializer.save()
            return JsonResponse({"message": "L'utilisateur a été mis à jour avec succès."}, status=200)
        return JsonResponse({"errors":serializer.errors}, status=400)

@api_view(['DELETE'])
@permission_classes([AllowAny])
@csrf_exempt
def delete_users(request,id):
    """Delete a user"""
    user = User.objects.get(id=id)
    user.delete()
    return JsonResponse({"message": "L'utilisateur a été supprimé avec succès."}, status=200)

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def change_recommanded(request,id):
    """Toggle the 'recommanted' status for a user."""
    user = User.objects.get(id=id)
    user.recommanted = not user.recommanted
    user.save()
    return JsonResponse({"message": "Le statut recommandé a été mis à jour avec succès."}, status=200)

@api_view(['POST'])
@permission_classes([AllowAny])
def forget_password(request):
    """forget a user password"""
    data = json.loads(request.body)
    try:
        user = User.objects.get(email=data['email'])
        send_verification_email(user)
        return JsonResponse({"is_exist": True,"user_id":user.pk}, status=200)
    except User.DoesNotExist:
        return JsonResponse({"message": "E-mail introuvable.","is_exist": False}, status=400)

@api_view(['POST'])
@permission_classes([AllowAny])
def verify_code(request,id):
    if request.method == 'POST':
        user = User.objects.get(id=id)
        data = json.loads(request.body)
        user_input = data['verification_code']
        print({"user_input":user_input})
        print({"user":user.pk})
        try:
            verification_code = VerificationCode.objects.get(user=user.pk)
            if timezone.now() <= verification_code.expiration_time:
                if user_input == verification_code.code:
                    verification_code.delete()
                    return JsonResponse({"verification": True}, status=200)
                return JsonResponse({"verification": False}, status=400)
           
            # Verification code expired
            verification_code.delete()
            return JsonResponse({"message": "Le code de vérification a expiré."}, status=200)
        except VerificationCode.DoesNotExist:
            return JsonResponse({"message": "Le code de vérification n'existe pas."}, status=400)
        
@api_view(['POST'])
@permission_classes([AllowAny])
def change_password(request, id):
    """Update a user password"""
    try:
        # Get the user instance
        user = User.objects.get(id=id)
    except User.DoesNotExist:
        return JsonResponse({"message": "Utilisateur non trouvé."}, status=404)
    data = json.loads(request.body)
    user.password = make_password(data['password'])
    user.save()
    return JsonResponse({"message": "Votre mot de passe a été mis à jour avec succès."}, status=200)

def generate_verification_code():
    return ''.join(random.choices(string.digits, k=6))

def send_verification_email(user):
    verification_code = generate_verification_code()
    expiration_time = timezone.now() + timedelta(minutes=30)
    VerificationCode.objects.update_or_create(user=user, defaults={'code': verification_code, 'expiration_time': expiration_time})
    subject = 'Vérifiez votre compte'
    text_message = 'Bienvenue,'
    message = f'<p>Bonjour,</p><p>Voici votre code pour vérifier votre compte :</p><p>{verification_code}</p>'
    recipient_list = [user.email]
    from_email = settings.EMAIL_HOST_USER 
    msg = EmailMultiAlternatives(subject, text_message, from_email, recipient_list)
    msg.attach_alternative(message, "text/html")
    msg.send()
import json
import random
import string
from .authentication import JWTAuthentication
from rest_framework.decorators import api_view, permission_classes,authentication_classes
from rest_framework.permissions import AllowAny
from django.contrib.auth import authenticate, login, logout
from datetime import datetime, timedelta
from .serializers import ObtainTokenSerializer,SingupSerializer
from django.http import JsonResponse
from django.core.cache import cache
from ekrili.custom_msg import * 
from users.models import User
from django.contrib.auth.hashers import make_password
from django.core.mail import EmailMultiAlternatives
from django.conf import settings
from django.utils import timezone
from django.contrib.auth import get_user_model
from .models import VerificationCode
from django.utils.translation import gettext_lazy as _
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import get_object_or_404
from django.utils import translation
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi
from rest_framework.response import Response
from rest_framework import status

User=get_user_model()

@swagger_auto_schema(
    method='post',
    request_body=ObtainTokenSerializer,
    responses={
        200: openapi.Response(
            description="Connexion réussie ou compte non vérifié",
            examples={
                "application/json": {
                    "message": "Connexion effectuée avec succès.",
                    "token": "JWT_TOKEN_HERE",
                    "CurrentUser": {
                        "id": 1,
                        "username": "eya",
                        "email": "eya@example.com",
                        "is_verified": True,
                        "is_admin": False
                    }
                }
            }
        ),
        400: openapi.Response(
            description="Identifiants invalides",
            examples={"application/json": {"error": "Identifiants invalides"}}
        )
    }
)
@api_view(['POST'])
@permission_classes([AllowAny])  # ou IsAdminUser si tu veux sécuriser
def admin_create_user(request):
    data = json.loads(request.body)
    is_admin = data.get('is_admin', False)

    data['password'] = make_password(data['password'])
    user = User.objects.create(
        first_name=data.get('first_name', ''),
        last_name=data.get('last_name', ''),
        email=data['email'],
        password=data['password'],
        is_admin=is_admin,
        is_verified=True,   # ✅ AUTO VERIFIED
        is_active=True
    )

    return JsonResponse({
        "message": "Utilisateur créé par admin",
        "CurrentUser": {
            "id": user.id,
            "email": user.email,
            "is_verified": user.is_verified,
            "is_admin": user.is_admin
        }
    }, status=200)

@api_view(['POST'])
@permission_classes([AllowAny])
def authentification(request):
    if request.method == "POST":
        data = json.loads(request.body)
        serializer = ObtainTokenSerializer(data=data)
        
        if serializer.is_valid():
            user_qs = User.objects.filter(email=data['email'])

            user = user_qs.first()
            user_auth=authenticate(request, username=data['email'], password=data['password'])
            if user and user_auth and not user.is_verified:
                current_user = {
                    "id": user.pk,
                    "username": user.first_name,
                    "email": user.email,
                    "is_verified":user.is_verified,
                    "is_admin":user.is_admin
                }
                send_verification_email(user)
                return JsonResponse({'error': "Compte utilisateur n'est pas verifié","CurrentUser": current_user}, status=200)
            
            if user_auth:
                login(request, user)

                # Create JWT token
                jwt_token = str(JWTAuthentication.create_jwt(user))

                # Build current user data
                current_user = {
                    "id": user.pk,
                    "username": user.first_name,
                    "email": user.email,
                    "is_verified":user.is_verified,
                    "is_admin":user.is_admin
                }

                # Cache the current user details
                cache.set('CurrentUser', current_user)

                # Update last expiration time
                user.token_last_expired = datetime.now() + timedelta(hours=settings.JWT_CONF['TOKEN_LIFETIME_HOURS'])
                user.save()

                return JsonResponse({'message': 'Connexion effectuée avec succès.', 'token': jwt_token, "CurrentUser": current_user}, status=200)
            
        return JsonResponse({'error': 'Identifiants invalides'}, status=400)


@api_view(['POST'])
@permission_classes([AllowAny])
def logout_view(request):
    try:
        logout(request)
        return JsonResponse({'message': 'Déconnexion effectuée avec succès.'}, status=200)
    except AttributeError:
        return JsonResponse({'error': "L'utilisateur n'est pas authentifié"}, status=400)


@api_view(['POST'])
@permission_classes([AllowAny])
def resend_verification_code(request, id):
    """Resend the verification code to the user."""
    if request.method == 'POST':
        # Retrieve user or return 404 if not found
        user = get_object_or_404(User, id=id)

        # Send the verification email with the new code
        send_verification_email(user)

        # Return a success message with HTTP status 200
        return JsonResponse({"message": "Le code de vérification a été renvoyé."}, status=200)
    
def generate_verification_code():
    return ''.join(random.choices(string.digits, k=6))

def send_verification_email(user):
    verification_code = generate_verification_code()
    expiration_time = timezone.now() + timedelta(minutes=30)
    print({"verification_code":verification_code})
    VerificationCode.objects.update_or_create(user=user, defaults={'code': verification_code, 'expiration_time': expiration_time})
    subject = 'Vérifiez votre compte'
    text_message = 'Bienvenue,'
    message = f'<p>Bonjour,</p><p>Merci de vous être inscrit. Voici votre code pour vérifier votre compte :</p><p>{verification_code}</p>'
    recipient_list = [user.email]
    from_email = settings.EMAIL_HOST_USER 
    msg = EmailMultiAlternatives(subject, text_message, from_email, recipient_list)
    msg.attach_alternative(message, "text/html")
    msg.send()
    
    
@api_view(['POST'])
@permission_classes([AllowAny])
def signup_view(request):
    """Create a new user"""
    data = request.body
    data = json.loads(data)
    data['password'] = make_password(data['password'])
    with translation.override('fr'):
        sing_in_serializer = SingupSerializer(data=data)
        if sing_in_serializer.is_valid():
            user = sing_in_serializer.save()
            current_user = {
                'username': user.first_name,
                'email': user.email,
                'id': user.id,
                'is_verified':user.is_verified,
                "is_admin":user.is_admin
            }
            send_verification_email(user)
            return JsonResponse({"CurrentUser":current_user}, status=200)
        else:
            return JsonResponse({'error': sing_in_serializer.errors}, status=400)

@api_view(['POST'])
@permission_classes([AllowAny])
def verify_code(request,id):
    if request.method == 'POST':
        user = User.objects.get(id=id)
        data = json.loads(request.body)
        user_input = data['verification_code']
        try:
            verification_code = VerificationCode.objects.get(user=user.pk)
            if timezone.now() <= verification_code.expiration_time:
                if user_input == verification_code.code:
                    user.is_verified = True
                    user.save()
                    verification_code.delete()
                    login(request, user)
                    user_dict = user.__dict__
                    current_user = {"id": user_dict['id'],"username":user_dict['first_name'],"email":user_dict['email'],"is_verified":user_dict['is_verified'],"is_admin":user_dict['is_admin']}
                    cache.set('CurrentUser', current_user)

                    user.token_last_expired=datetime.now()+timedelta(hours=settings.JWT_CONF['TOKEN_LIFETIME_HOURS'])
                    user.save()
                    return JsonResponse({"message": "Authentification réussie.","CurrentUser":current_user}, status=200)
                return JsonResponse({"message": "Identifiants invalides."}, status=400)
           
            # Verification code expired
            verification_code.delete()
            return JsonResponse({"message": "Le code de vérification a expiré."}, status=200)
        except VerificationCode.DoesNotExist:
            return JsonResponse({"message": "Le code de vérification n'existe pas."}, status=400)
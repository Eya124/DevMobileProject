from datetime import datetime, timedelta
import jwt
from django.conf import settings
from django.contrib.auth import get_user_model
from rest_framework import authentication
from rest_framework.exceptions import AuthenticationFailed

User = get_user_model()

class JWTAuthentication(authentication.BaseAuthentication):
    
    def authenticate(self, request):
        # Extract token from HTTP header
        jwt_token = self.get_the_token_from_header(request.META.get('HTTP_AUTHORIZATION'))
        
        if not jwt_token:
            return None

        try:
            # Decode the JWT token with the secret key
            payload = jwt.decode(jwt_token, settings.SECRET_KEY, algorithms=['HS256'], options={"verify_exp": True},audience=settings.JWT_CONF['JWT_AUDIENCE'] )
        except jwt.ExpiredSignatureError:
            raise AuthenticationFailed('Token has expired')
        except jwt.InvalidTokenError as exc:
            raise AuthenticationFailed(f'Invalid token: {str(exc)}')

        user_id = payload.get('user_identifier')
        if user_id is None:
            raise AuthenticationFailed('User identifier not found in JWT')
        
        user = User.objects.filter(id=user_id).first()
        if user is None:
            raise AuthenticationFailed('User not found')

        return user, payload

    def authenticate_header(self, request):
        return 'Bearer'

    @classmethod
    def create_jwt(cls, user):
        # Generate JWT token with extended expiration and user info
        payload = {
            'user_identifier': user.id,
            'exp': int((datetime.now() + timedelta(hours=settings.JWT_CONF['TOKEN_LIFETIME_HOURS'])).timestamp()),
            'iat': datetime.now().timestamp(),
            'email': user.email,
            'is_active': user.is_active
        }

        # Optionally, add an audience (aud) field to tighten security
        payload['aud'] = settings.JWT_CONF.get('JWT_AUDIENCE', 'my_app')

        jwt_token = jwt.encode(payload, settings.SECRET_KEY, algorithm='HS256')
        return jwt_token

    @staticmethod
    def get_the_token_from_header(authorization_header):
        # Remove 'Bearer' if it exists and clean up spaces
        if authorization_header and authorization_header.lower().startswith('bearer '):
            return authorization_header.split(' ', 1)[1].strip()
        return None

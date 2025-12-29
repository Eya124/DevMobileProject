from rest_framework import serializers
from users.models import User

class ObtainTokenSerializer(serializers.Serializer):
    email = serializers.CharField()
    password = serializers.CharField()

class SingupSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields ='__all__'
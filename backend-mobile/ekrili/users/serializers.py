from rest_framework import serializers
from users.models import User

class SingInSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields ='__all__'

class UpdateUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields =['last_name','first_name','phone_number','state','delegation','jurisdiction']
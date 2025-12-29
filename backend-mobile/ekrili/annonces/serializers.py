from rest_framework import serializers
from annonces.models import *
from images.models import Image

class AnnonceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Annonce
        fields ='__all__'
        
class StateSerializer(serializers.ModelSerializer):
    class Meta:
        model = State
        fields ='__all__'
        
class DelegationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Delegation
        fields ='__all__'
        
class JurisdictionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Jurisdiction
        fields ='__all__'
        
        
class ImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Image
        fields = ['image_url']

class AllAnnonceSerializer(serializers.ModelSerializer):
    images = ImageSerializer(many=True, read_only=True)

    class Meta:
        model = Annonce
        fields = '__all__'

    user_id = serializers.IntegerField(source='user.pk', read_only=True)
    delegation = serializers.CharField(source='delegation.name', read_only=True)
    jurisdiction = serializers.CharField(source='jurisdiction.name', read_only=True)
    state = serializers.CharField(source='state.name', read_only=True)
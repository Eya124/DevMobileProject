from rest_framework import serializers
from historique.models import Historique

class HistoriqueSerializer(serializers.ModelSerializer):
    class Meta:
        model = Historique
        fields ='__all__'
from rest_framework import serializers

from chatbot.models import Chatbot
class   ChatbotSerializer(serializers.ModelSerializer):
    class Meta:
            model = Chatbot
            fields ='__all__'

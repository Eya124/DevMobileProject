from rest_framework import serializers

# interction with bdd (ORM)
from feedback.models import Feedback
class FeedbackSerializer(serializers.ModelSerializer):
    class Meta:
            model = Feedback
            fields ='__all__'

from django.db import models
from users.models import User
from type.models import Type
# Create your models here.

class State(models.Model):
    name = models.CharField(max_length=150)
    class Meta:
        db_table = 'states'
        managed = False
    def __str__(self):
        return self.name

class Delegation(models.Model):
    name = models.CharField(max_length=150)
    state = models.ForeignKey(State, on_delete=models.CASCADE)
    class Meta:
        db_table = 'delegations'
        managed = False
    def __str__(self):
        return self.name
         
class Jurisdiction(models.Model):
    name = models.CharField(max_length=150)
    delegation = models.ForeignKey(Delegation, on_delete=models.CASCADE)
    class Meta:
        db_table = 'jurisdictions'
        managed = False
    def __str__(self):
        return self.name
        
class Annonce(models.Model):
    title = models.CharField(max_length=1000)
    description = models.CharField(max_length=1000, null=True,blank=True)
    size = models.CharField(max_length=100)
    price = models.IntegerField()
    state = models.ForeignKey(State, on_delete=models.CASCADE)
    delegation = models.ForeignKey(Delegation, on_delete=models.CASCADE, null=True, blank=True)
    jurisdiction = models.ForeignKey(Jurisdiction , on_delete=models.CASCADE, null=True,blank=True)
    status = models.BooleanField(default=True)
    type = models.ForeignKey(Type, on_delete=models.CASCADE)
    localisation = models.CharField(max_length=500, null=True,blank=True)
    date_posted = models.DateField()
    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True,blank=True)
    phone = models.IntegerField()
    id_folder = models.CharField(max_length=200,unique=True,blank=True,null=True)
    url = models.CharField(max_length=1500,blank=True,null=True)
    class Meta:
        db_table = 'annonces'
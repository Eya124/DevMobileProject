import os
import shutil
import urllib
from annonces.models import *
from annonces.tasks import recommend_annonce_from_celery
from images.models import Image
from annonces.serializers import *
from django.conf import settings
from images.serializers import ImageSerializer
from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from django.views.decorators.csrf import csrf_exempt
from django.core.files.storage import FileSystemStorage
from datetime import datetime
from annonces.constants import STATE_COORDINATES
from django.utils import translation
from django.db.models import Case, When, Value, BooleanField
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from authentification.authentication import JWTAuthentication
# Create your views here.


@csrf_exempt
def add_annonce(request):
    """Create a new annonce with images"""

    if not request.content_type.startswith('multipart/form-data'):
        return JsonResponse({'error': 'Type de contenu non pris en charge.Type de contenu non pris en charge.'}, status=415)
    
    # Extract POST data and files
    data = request.POST.copy()
    image_files = request.FILES.getlist('images')
    # Clean and convert data
    try:
        if data.get('delegation') != 'undefined':
            data['delegation'] = int(data['delegation'])
        else:
            data['delegation'] = None  # or any default value

        if data.get('jurisdiction') != 'undefined':
            data['jurisdiction'] = int(data['jurisdiction'])
        else:
            data['jurisdiction'] = None
        data['price'] = int(data['price'])
        data['user'] = int(data['user']) if data.get('user') else None
        data['state'] = int(data['state'])
        data['type'] = int(data['type'])
        data['status'] = True
        data['size'] = "s+"+data['size']
        data['date_posted'] = datetime.now().strftime("%Y-%m-%d")
    except (ValueError, KeyError) as e:
        return JsonResponse({'error': f'Invalid data: {str(e)}'}, status=400)
    with translation.override('fr'):
        # Serialize and save annonce
        annonce_serializer = AnnonceSerializer(data=data)
        if not annonce_serializer.is_valid():
            return JsonResponse({'error': annonce_serializer.errors}, status=400)

        annonce = annonce_serializer.save()
        base_url = "http://localhost:5173"
        annonce_url = base_url+"/annonces/"+str(annonce.pk)+"/details"
        
        print({"annonce_url":annonce_url})
        # Handle image uploads
        folder_path = os.path.join(settings.MEDIA_ROOT, str(annonce.pk))
        os.makedirs(folder_path, exist_ok=True)
        fs = FileSystemStorage(location=folder_path)

        for image_file in image_files:
            filename = fs.save(image_file.name, image_file)  # Save image
            image_url = os.path.join(settings.MEDIA_URL, str(annonce.pk), filename)
            image_data = {"image_url": image_url.replace('\\','/'), "annonce": annonce.id}

            # Serialize and save image
            image_serializer = ImageSerializer(data=image_data)
            if not image_serializer.is_valid():
                return JsonResponse({'error': image_serializer.errors}, status=400)
            image_serializer.save()
        recommend_annonce_from_celery.apply_async(args=[annonce.id], countdown=10)
        return JsonResponse({'message': 'Annonce crée avec succès.',"url":annonce_url}, status=200)

# def all_annonce(request):
#     """Retrieve all annonces"""
#     annonces = Annonce.objects.prefetch_related('images').all()  # Use 'images' here
#     serializer = AllAnnonceSerializer(annonces, many=True)
#     return JsonResponse({'list_annonces': serializer.data})
@api_view(['GET'])
@permission_classes([])  
def all_annonce(request):
    """Retrieve all annonces"""
    if request.method == 'GET':
        list_annonces = []
        list_images = []
        annonce_json = {}
        annonces = Annonce.objects.annotate(
            is_url_null=Case(
                When(url__isnull=True, then=Value(True)),
                default=Value(False),
                output_field=BooleanField()
            )
        ).order_by('-is_url_null', '-id', 'url')
        
        for annonce in annonces:
            annonce_json['id'] = annonce.pk
            if annonce.user:
                annonce_json['user_id'] = annonce.user.pk
                # annonce_json['user_phone'] = annonce.user.phone_number
                annonce_json['user_email'] = annonce.user.email
                
            annonce_json['type'] = annonce.type.name
            annonce_json['phone'] = annonce.phone
            annonce_json['title'] = annonce.title
            annonce_json['description'] = annonce.description
            annonce_json['size'] = annonce.size
            annonce_json['price'] = annonce.price
            annonce_json['state'] = annonce.state.name
            annonce_json['delegation'] = annonce.delegation.name if annonce.delegation else ''
            annonce_json['jurisdiction'] = annonce.jurisdiction.name if annonce.jurisdiction else ''
            annonce_json['status'] = annonce.status
            annonce_json['localisation'] = annonce.localisation
            annonce_json['date_posted'] = annonce.date_posted
            annonce_json['id_folder'] = annonce.id_folder
            annonce_json['url'] = annonce.url
            images = Image.objects.filter(annonce_id=annonce.pk)
            for image in images:
                list_images.append(image.image_url)
            annonce_json['images'] = list_images
            list_annonces.append(annonce_json)
            annonce_json = {}
            list_images = []
        return JsonResponse({'number_annonce':len(list_annonces),'list_annonces': list_annonces}, status=200)
    return JsonResponse({'error': 'Invalid method'}, status=405)


def all_annonce_for_map(request):
    """Retrieve all annonces"""
    if request.method == 'GET':
        annonces_with_coords = []
        list_images = []
        annonces = Annonce.objects.all()
        
        for annonce in annonces:
            images = Image.objects.filter(annonce_id=annonce.pk)
            for image in images:
                list_images.append(image.image_url)
            coords = STATE_COORDINATES.get(annonce.state.name)
            if coords:
                annonces_with_coords.append({
                    'id': annonce.pk,
                    'title': annonce.title,
                    'description': annonce.description,
                    'latitude': coords[0],
                    'longitude': coords[1],
                    'phone':annonce.phone,
                    'type':annonce.type.name,
                    'size':annonce.size,
                    'price':annonce.price,
                    'phone':annonce.phone,
                    'delegation':annonce.delegation.name if annonce.delegation else '',
                    'jurisdiction':annonce.jurisdiction.name if annonce.jurisdiction else '',
                    'date_posted':annonce.date_posted,
                    'images':list_images,
                })
            list_images = []
        return JsonResponse({'annonces_with_coords': annonces_with_coords}, status=200)
    return JsonResponse({'error': 'Invalid method'}, status=405)

@csrf_exempt
def annonce(request,id):
    """Retrieve annonce by id"""
    if request.method == 'GET':
        list_images = []
        annonce_json = {}
        annonce = Annonce.objects.get(id=id)
        
        annonce_json['id'] = annonce.pk
        if annonce.user:
            annonce_json['user_id'] = annonce.user.pk
            # annonce_json['user_phone'] = annonce.user.phone_number
            annonce_json['user_email'] = annonce.user.email
            
        annonce_json['type'] = annonce.type.name
        annonce_json['phone'] = annonce.phone
        annonce_json['title'] = annonce.title
        annonce_json['description'] = annonce.description
        annonce_json['size'] = annonce.size
        annonce_json['price'] = annonce.price
        annonce_json['state'] = annonce.state.name
        annonce_json['delegation'] = annonce.delegation.name if annonce.delegation else ''
        annonce_json['jurisdiction'] = annonce.jurisdiction.name if annonce.jurisdiction else ''
        annonce_json['status'] = annonce.status
        annonce_json['localisation'] = annonce.localisation
        annonce_json['date_posted'] = annonce.date_posted
        images = Image.objects.filter(annonce_id=annonce.pk)
        for image in images:
            list_images.append(image.image_url)
        annonce_json['images'] = list_images
        return JsonResponse({'annonce': annonce_json}, status=200)
    return JsonResponse({'error': 'Invalid method'}, status=405)

@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def all_annonce_by_user(request,id):
    """Retrieve all annonces by current user"""
    if request.method == 'GET':
        list_annonces = []
        list_images = []
        annonce_json = {}
        annonces = Annonce.objects.filter(user_id=id)
        
        for annonce in annonces:
            annonce_json['id'] = annonce.pk
            annonce_json['user_id'] = annonce.user.pk
            annonce_json['user_phone'] = annonce.phone
            annonce_json['user_email'] = annonce.user.email
            annonce_json['type'] = annonce.type.name
            annonce_json['title'] = annonce.title
            annonce_json['description'] = annonce.description
            annonce_json['size'] = annonce.size
            annonce_json['price'] = annonce.price
            annonce_json['state'] = annonce.state.name
            annonce_json['delegation'] = annonce.delegation.name if annonce.delegation else ''
            annonce_json['jurisdiction'] = annonce.jurisdiction.name if annonce.jurisdiction else ''
            annonce_json['status'] = annonce.status
            annonce_json['localisation'] = annonce.localisation
            annonce_json['date_posted'] = annonce.date_posted
            images = Image.objects.filter(annonce_id=annonce.pk)
            for image in images:
                list_images.append(image.image_url)
            annonce_json['images'] = list_images
            list_annonces.append(annonce_json)
            annonce_json = {}
            list_images = []

        return JsonResponse({'all_annonces': list_annonces}, status=200)
    return JsonResponse({'error': 'Invalid method'}, status=405)
    

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def update_annonce(request, id):
    """Update an existing annonce with new data and images"""
    if not request.content_type.startswith('multipart/form-data'):
        return JsonResponse({'error': 'Unsupported content type'}, status=415)

    # Extract POST data and files
    data = request.POST.copy()
    image_files = request.FILES.getlist('images')
    
    # Clean and convert fields
    try:
        data['price'] = int(data['price'])
        data['state'] = int(data['state'])
        data['delegation'] = int(data['delegation'])
        data['jurisdiction'] = int(data['jurisdiction'])
        data['type'] = int(data['type'])
    except (ValueError, KeyError) as e:
        return JsonResponse({'error': f'Invalid data: {str(e)}'}, status=400)

    # Retrieve and update the existing annonce
    annonce = get_object_or_404(Annonce, id=id)
    with translation.override('fr'):
        annonce_serializer = AnnonceSerializer(annonce, data=data, partial=True)

        # Validate and save the annonce update
        if not annonce_serializer.is_valid():
            return JsonResponse({'error': annonce_serializer.errors}, status=400)

        # Update the `date_posted` field before saving
        annonce.date_posted = datetime.now().strftime("%Y-%m-%d")
        annonce = annonce_serializer.save()  # Save the serializer once with all changes

        # Handle image uploads
        folder_path = os.path.join(settings.MEDIA_ROOT, str(annonce.pk))
        fs = FileSystemStorage(location=folder_path)
        # Get existing images associated with the annonce
        existing_images = Image.objects.filter(annonce=annonce.id)
        existing_image_urls = [os.path.basename(image.image_url) for image in existing_images]

        # Delete old images not in the uploaded list
        for existing_image_url in existing_image_urls:
            if existing_image_url not in [image_file.name for image_file in image_files]:
                os.remove(os.path.join(folder_path, urllib.parse.unquote(existing_image_url)))
                Image.objects.filter(image_url__endswith=existing_image_url,annonce=annonce.id).delete()

        # Save new images that are not already associated
        for image_file in image_files:
            if image_file.name not in existing_image_urls:
                filename = fs.save(image_file.name, image_file)
                image_url = f"/media/{annonce.pk}/{urllib.parse.unquote(filename)}"

                # Save image in the database
                image_data = {"image_url": image_url, "annonce": annonce.id}
                image_serializer = ImageSerializer(data=image_data)
                if image_serializer.is_valid():
                    image_serializer.save()
                else:
                    return JsonResponse({'errors': image_serializer.errors}, status=400)

        return JsonResponse({'message': "L'annonce a été mis à jour avec succès"}, status=200)
    
@api_view(['PUT'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def update_status(request, id):
    """Toggle the status for a annonce."""
    annonce = Annonce.objects.get(id=id)
    annonce.status = not annonce.status
    annonce.save()
    return JsonResponse({"message": "Le statut d'annonce a été mis à jour avec succès."}, status=200)

@api_view(['DELETE'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def delete_annonce(request, id):
    """Delete an annonce by ID"""
    try:
        annonce = Annonce.objects.get(id=id)
        images = Image.objects.filter(annonce=annonce.pk)
    except Annonce.DoesNotExist:
        return JsonResponse({'error': 'Annonce introuvable'}, status=404)

    if request.method == 'DELETE':
        for image in images:
            if annonce.url is not None:
                file_path = str(settings.BASE_DIR) + image.image_url
                folder_path = str(settings.BASE_DIR) + os.path.dirname(image.image_url)
                
            else:
                folder_path = os.path.join(settings.MEDIA_ROOT, str(annonce.pk))
                name_image = image.image_url.split('/')[3].replace('%20',' ')
                file_path = os.path.join(folder_path, name_image)

            os.remove(file_path)
        if os.path.exists(folder_path) and os.path.isdir(folder_path):
            shutil.rmtree(folder_path)
        try:
            annonce.delete()
            return JsonResponse({'message': "L'annonce a été supprimé avec succès."}, status=200)
        except Exception as e:
            print(f"Error deleting annonce: {e}")
            return JsonResponse({'error': f"Erreur lors de la suppression de l'annonce: {e}"}, status=400)
        

def all_states(request):
    states = list(State.objects.values()) 
    return JsonResponse({'states': states}, status=200)

def all_delegations_by_state(request,state_id):
    delegations_by_state = list(Delegation.objects.filter(state_id=state_id).values())  
    return JsonResponse({'delegations_by_state': delegations_by_state}, status=200)

def all_jurisdictions_by_delegation(request,delegation_id):
    jurisdictions_by_delegation = list(Jurisdiction.objects.filter(delegation_id=delegation_id).values())  
    return JsonResponse({'jurisdictions_by_delegation': jurisdictions_by_delegation}, status=200)
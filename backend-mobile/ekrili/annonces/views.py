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
from rest_framework import status

@csrf_exempt
def add_annonce(request):
    """Create a new annonce with images"""

    if not request.content_type.startswith('multipart/form-data'):
        return JsonResponse({'error': 'Type de contenu non pris en charge.'}, status=415)
    
    # Extract POST data and files
    data = request.POST.copy()
    image_files = request.FILES.getlist('images')

    # Clean and convert data safely
    try:
        # 1. Handle Delegation
        delegation = data.get('delegation')
        if delegation and delegation != 'undefined' and str(delegation).strip() != '':
            data['delegation'] = int(delegation)
        else:
            data['delegation'] = None

        # 2. Handle Jurisdiction (Fixed the crash here)
        jurisdiction = data.get('jurisdiction')
        if jurisdiction and jurisdiction != 'undefined' and str(jurisdiction).strip() != '':
            data['jurisdiction'] = int(jurisdiction)
        else:
            data['jurisdiction'] = None

        # 3. Handle Numeric Fields
        data['price'] = int(data.get('price', 0))
        
        # Check if user/state/type are provided and are digits
        user_val = data.get('user')
        data['user'] = int(user_val) if user_val and str(user_val).isdigit() else None
        
        state_val = data.get('state')
        data['state'] = int(state_val) if state_val and str(state_val).isdigit() else None
        
        type_val = data.get('type')
        data['type'] = int(type_val) if type_val and str(type_val).isdigit() else None

        # 4. Handle Status and Size
        data['status'] = True
        current_size = data.get('size', 'S')
        data['size'] = f"s+{current_size}"
        data['date_posted'] = datetime.now().strftime("%Y-%m-%d")

    except (ValueError, KeyError, TypeError) as e:
        print(f"Extraction Error: {e}")
        return JsonResponse({'error': f'Invalid data format: {str(e)}'}, status=400)

    with translation.override('fr'):
        # Serialize and save annonce
        annonce_serializer = AnnonceSerializer(data=data)
        if not annonce_serializer.is_valid():
            print(f"Serializer Errors: {annonce_serializer.errors}")
            return JsonResponse({'error': annonce_serializer.errors}, status=400)

        annonce = annonce_serializer.save()
        
        # Set up response URL
        base_url = "http://localhost:5173"
        annonce_url = f"{base_url}/annonces/{annonce.pk}/details"
        
        # Handle image uploads
        folder_path = os.path.join(settings.MEDIA_ROOT, str(annonce.pk))
        os.makedirs(folder_path, exist_ok=True)
        fs = FileSystemStorage(location=folder_path)

        for image_file in image_files:
            filename = fs.save(image_file.name, image_file)
            image_url = os.path.join(settings.MEDIA_URL, str(annonce.pk), filename)
            image_data = {
                "image_url": image_url.replace('\\', '/'), 
                "annonce": annonce.id
            }

            # Serialize and save image
            img_serializer = ImageSerializer(data=image_data)
            if img_serializer.is_valid():
                img_serializer.save()
            else:
                print(f"Image Serializer Error: {img_serializer.errors}")
                # We continue even if one image fails, or you can return error
        
        # Trigger background task
        print(f"Task skipped: Recommend annonce {annonce.id}")        
        return JsonResponse({
            'message': 'Annonce créée avec succès.',
            "url": annonce_url
        }, status=200)

@api_view(['GET'])
@permission_classes([])  
def all_annonce(request):
    """Retrieve all annonces"""
    annonces = Annonce.objects.annotate(
        is_url_null=Case(
            When(url__isnull=True, then=Value(True)),
            default=Value(False),
            output_field=BooleanField()
        )
    ).order_by('-is_url_null', '-id', 'url')
    
    list_annonces = []
    for annonce in annonces:
        images = Image.objects.filter(annonce_id=annonce.pk)
        list_images = [img.image_url for img in images]
        
        annonce_json = {
            'id': annonce.pk,
            'user_id': annonce.user.pk if annonce.user else None,
            'user_email': annonce.user.email if annonce.user else None,
            'type': annonce.type.name if annonce.type else None,
            'phone': annonce.phone,
            'title': annonce.title,
            'description': annonce.description,
            'size': annonce.size,
            'price': annonce.price,
            'state': annonce.state.name if annonce.state else None,
            'delegation': annonce.delegation.name if annonce.delegation else '',
            'jurisdiction': annonce.jurisdiction.name if annonce.jurisdiction else '',
            'status': annonce.status,
            'localisation': annonce.localisation,
            'date_posted': annonce.date_posted,
            'id_folder': annonce.id_folder,
            'url': annonce.url,
            'images': list_images
        }
        list_annonces.append(annonce_json)
        
    return JsonResponse({'number_annonce': len(list_annonces), 'list_annonces': list_annonces}, status=200)

def all_annonce_for_map(request):
    """Retrieve all annonces with coordinates"""
    if request.method != 'GET':
        return JsonResponse({'error': 'Invalid method'}, status=405)
        
    annonces_with_coords = []
    annonces = Annonce.objects.all()
    
    for annonce in annonces:
        images = Image.objects.filter(annonce_id=annonce.pk)
        list_images = [img.image_url for img in images]
        
        coords = STATE_COORDINATES.get(annonce.state.name) if annonce.state else None
        if coords:
            annonces_with_coords.append({
                'id': annonce.pk,
                'title': annonce.title,
                'description': annonce.description,
                'latitude': coords[0],
                'longitude': coords[1],
                'phone': annonce.phone,
                'type': annonce.type.name if annonce.type else None,
                'size': annonce.size,
                'price': annonce.price,
                'delegation': annonce.delegation.name if annonce.delegation else '',
                'jurisdiction': annonce.jurisdiction.name if annonce.jurisdiction else '',
                'date_posted': annonce.date_posted,
                'images': list_images,
            })
    return JsonResponse({'annonces_with_coords': annonces_with_coords}, status=200)

@csrf_exempt
def annonce(request, id):
    """Retrieve single annonce by id"""
    if request.method != 'GET':
        return JsonResponse({'error': 'Invalid method'}, status=405)
        
    try:
        annonce = Annonce.objects.get(id=id)
        images = Image.objects.filter(annonce_id=annonce.pk)
        list_images = [img.image_url for img in images]
        
        annonce_data = {
            'id': annonce.pk,
            'user_id': annonce.user.pk if annonce.user else None,
            'user_email': annonce.user.email if annonce.user else None,
            'type': annonce.type.name if annonce.type else None,
            'phone': annonce.phone,
            'title': annonce.title,
            'description': annonce.description,
            'size': annonce.size,
            'price': annonce.price,
            'state': annonce.state.name if annonce.state else None,
            'delegation': annonce.delegation.name if annonce.delegation else '',
            'jurisdiction': annonce.jurisdiction.name if annonce.jurisdiction else '',
            'status': annonce.status,
            'localisation': annonce.localisation,
            'date_posted': annonce.date_posted,
            'images': list_images
        }
        return JsonResponse({'annonce': annonce_data}, status=200)
    except Annonce.DoesNotExist:
        return JsonResponse({'error': 'Annonce introuvable'}, status=404)

@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def all_annonce_by_user(request, id):
    """Retrieve all annonces by specific user id"""
    annonces = Annonce.objects.filter(user_id=id)
    list_annonces = []
    
    for annonce in annonces:
        images = Image.objects.filter(annonce_id=annonce.pk)
        list_images = [img.image_url for img in images]
        
        item = {
            'id': annonce.pk,
            'user_id': annonce.user.pk,
            'user_phone': annonce.phone,
            'user_email': annonce.user.email,
            'type': annonce.type.name,
            'title': annonce.title,
            'description': annonce.description,
            'size': annonce.size,
            'price': annonce.price,
            'state': annonce.state.name,
            'delegation': annonce.delegation.name if annonce.delegation else '',
            'jurisdiction': annonce.jurisdiction.name if annonce.jurisdiction else '',
            'status': annonce.status,
            'localisation': annonce.localisation,
            'date_posted': annonce.date_posted,
            'images': list_images
        }
        list_annonces.append(item)
    return JsonResponse({'all_annonces': list_annonces}, status=200)
@csrf_exempt
@api_view(['POST', 'PUT'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def update_annonce(request, id):
    """Update an existing annonce. Explicitly allowing POST and PUT."""
    
    # 1. Handle Method check manually just in case
    if request.method not in ['POST', 'PUT']:
        return JsonResponse({'error': f'Method {request.method} not allowed'}, status=405)

    # 2. Check content type
    if not request.content_type.startswith('multipart/form-data'):
        return JsonResponse({'error': 'Unsupported content type. Use multipart/form-data'}, status=415)

    data = request.POST.copy()
    image_files = request.FILES.getlist('images')
    
    # 3. Sanitize and convert IDs safely
    try:
        if data.get('price'): data['price'] = int(data.get('price'))
        if data.get('state'): data['state'] = int(data.get('state'))
        if data.get('type'): data['type'] = int(data.get('type'))
        
        for field in ['delegation', 'jurisdiction']:
            val = data.get(field)
            if val and val not in ['null', 'undefined', '']:
                data[field] = int(val)
            else:
                data[field] = None
                
    except (ValueError, KeyError) as e:
        return JsonResponse({'error': f'Invalid numeric data: {str(e)}'}, status=400)

    annonce = get_object_or_404(Annonce, id=id)
    
    with translation.override('fr'):
        annonce_serializer = AnnonceSerializer(annonce, data=data, partial=True)

        if not annonce_serializer.is_valid():
            return JsonResponse({'error': annonce_serializer.errors}, status=400)

        annonce.date_posted = datetime.now().strftime("%Y-%m-%d")
        annonce = annonce_serializer.save()

        # 4. Image Management
        folder_path = os.path.join(settings.MEDIA_ROOT, str(annonce.pk))
        os.makedirs(folder_path, exist_ok=True)
        fs = FileSystemStorage(location=folder_path)
        
        existing_images = Image.objects.filter(annonce=annonce.id)
        new_request_filenames = [f.name for f in image_files]

        # Cleanup old images
        for old_img in existing_images:
            old_filename = os.path.basename(old_img.image_url)
            if old_filename not in new_request_filenames:
                file_path = os.path.join(folder_path, urllib.parse.unquote(old_filename))
                if os.path.exists(file_path):
                    os.remove(file_path)
                old_img.delete()

        # Save new images
        existing_filenames = [os.path.basename(img.image_url) for img in Image.objects.filter(annonce=annonce.id)]
        for image_file in image_files:
            if image_file.name not in existing_filenames:
                filename = fs.save(image_file.name, image_file)
                image_url = os.path.join(settings.MEDIA_URL, str(annonce.pk), filename).replace('\\', '/')
                img_data = {"image_url": image_url, "annonce": annonce.id}
                img_serializer = ImageSerializer(data=img_data)
                if img_serializer.is_valid():
                    img_serializer.save()

        return JsonResponse({'message': "L'annonce a été mise à jour avec succès"}, status=200)
    
@api_view(['PUT'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def update_status(request, id):
    """Toggle the status for an annonce."""
    annonce = get_object_or_404(Annonce, id=id)
    annonce.status = not annonce.status
    annonce.save()
    return JsonResponse({"message": "Le statut a été mis à jour avec succès."}, status=200)

@api_view(['DELETE'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def delete_annonce(request, id):
    """Delete an annonce and its associated media folder"""
    annonce = get_object_or_404(Annonce, id=id)
    folder_path = os.path.join(settings.MEDIA_ROOT, str(annonce.pk))
    
    try:
        if os.path.exists(folder_path):
            shutil.rmtree(folder_path)
        annonce.delete()
        return JsonResponse({'message': "L'annonce a été supprimée avec succès."}, status=200)
    except Exception as e:
        return JsonResponse({'error': f"Erreur lors de la suppression: {e}"}, status=400)

def all_states(request):
    # Ensure this returns a list of dictionaries with 'id' and 'name'
    states = list(State.objects.values('id', 'name')) 
    return JsonResponse({'states': states}, status=200)

def all_types(request):
    # Some Flutter code expects a List, others expect {'types': [...]}
    # Let's return a direct list as it's the most common
    types = list(Type.objects.values('id', 'name'))
    return JsonResponse(types, safe=False)

def all_delegations_by_state(request, state_id):
    delegations = list(Delegation.objects.filter(state_id=state_id).values())  
    return JsonResponse({'delegations_by_state': delegations}, status=200)

def all_jurisdictions_by_delegation(request, delegation_id):
    jurisdictions = list(Jurisdiction.objects.filter(delegation_id=delegation_id).values())  
    return JsonResponse({'jurisdictions_by_delegation': jurisdictions}, status=200)
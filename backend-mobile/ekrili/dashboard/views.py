from users.models import User
from historique.models import Historique
from annonces.models import Annonce, State, Delegation, Jurisdiction
from django.http import JsonResponse
from django.db.models import Q
from django.http import JsonResponse
import json
from django.db.models import Count
from collections import Counter
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from authentification.authentication import JWTAuthentication
# Create your views here.

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def dashboard(request):
    users = User.objects.filter(is_admin=False).values()  
    user_list = []

    for user in users:
        if 'last_login' in user:
            del user['last_login']
        if 'password' in user:
            del user['password']
        if 'is_admin' in user:
            del user['is_admin']
        if 'token_last_expired' in user:
            del user['token_last_expired']
        if 'state_id' in user and user['state_id']:
            user['state_id'] = State.objects.get(id=user['state_id'])
        else:
            del user['state_id']
        if 'delegation_id' in user and user['delegation_id']:
            user['delegation_id'] = Delegation.objects.get(id=user['delegation_id'])
        else:
            del user['delegation_id']
        if 'jurisdiction_id' in user and user['jurisdiction_id']:
            user['jurisdiction_id'] = Jurisdiction.objects.get(id=user['jurisdiction_id'])
        else:
            del user['jurisdiction_id']
        if not user['phone_number']:
            del user['phone_number']
        user_list.append(user)
        
        # Fetch all annonces
        annonces_data = Annonce.objects.all()

        # --- 1. Group by Date Posted ---
        date_labels = []
        date_counts = []
        for annonce in annonces_data.values('date_posted').annotate(count=Count('id')).order_by('date_posted'):
            date_labels.append(annonce['date_posted'])
            date_counts.append(annonce['count'])

        # --- 2. Price Distribution (With updated bins) ---
        # Fetch all prices from annonces_data
        prices = list(annonces_data.values_list('price', flat=True))
        
        # Remove 0 values
        filtered_prices = [price for price in prices if price != 0]

        # Count occurrences of each price
        price_counts = Counter(filtered_prices)

        # Sort the labels (prices) in ascending order
        sorted_labels = sorted(price_counts.keys())

        # Prepare the sorted data for the bar chart
        sorted_values = [price_counts[label] for label in sorted_labels]
        
        # --- 3. Group by State ---
        states = list(Annonce.objects.values('state__name').annotate(count=Count('id')))
        state_labels = [state['state__name'] for state in states]
        state_counts = [state['count'] for state in states]

        # --- 4. Group by size ---
        size_labels = []
        size_counts = []
        for annonce in annonces_data.values('size').annotate(count=Count('id')).order_by('size'):
            size_labels.append(annonce['size'])
            size_counts.append(annonce['count'])
            
        # --- 4. Group by type ---
        types = list(Annonce.objects.values('type__name').annotate(count=Count('id')))
        type_labels = [type['type__name'] for type in types]  # List of all the types
        type_counts = [type['count'] for type in types]
        
        # Convert the data to JSON format to pass to the template
        date_data = {'labels': [str(date) for date in date_labels], 'counts': date_counts}
        price_data = {'bins': sorted_labels, 'counts': sorted_values}
        state_data = {'labels': state_labels, 'counts': state_counts}
        size_data = {'labels': size_labels, 'counts': size_counts}
        type_data = {'labels': type_labels, 'counts': type_counts}
        
        annonces={
        'date_data': date_data,
        'price_data': price_data,
        'state_data': state_data,
        'size_data': size_data,
        'type_data': type_data,
    }
    return JsonResponse({'user_list': user_list,'count':len(user_list),'annonces':annonces}, status=200)

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def get_filtered_users(request):
    # Only accept POST requests
    if request.method == 'POST':
        # Parse the JSON body of the request
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)

        # Initialize the query with an empty Q object (AND conditions)
        query = Q()

        # Extract filters from the request body
        is_verified = data.get('is_verified', None)
        is_active = data.get('is_active', None)
        state = data.get('state', None)

        # Dynamically add filters based on the provided data
        if is_verified is not None:
            query &= Q(is_verified=is_verified)

        if is_active is not None:
            query &= Q(is_active=is_active)

        if state is not None:
            query &= Q(state__icontains=state)  # Case-insensitive search for state

        # Apply the filter and get the filtered users
        users = User.objects.filter(query)

        # Serialize the user data (convert to list of dictionaries)
        user_list = list(users.values('id', 'first_name', 'last_name', 'email', 'is_verified', 'is_active', 'state'))

        # Return the response
        return JsonResponse({'user_list': user_list,'count':len(user_list)}, status=200)

    else:
        return JsonResponse({'error': 'Only POST requests are allowed.'}, status=405)
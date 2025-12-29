import json
from historique.models import Historique
from type.models import Type
from historique.serializers import HistoriqueSerializer
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from datetime import datetime
from django.core import serializers
from collections import defaultdict
from historique.function import *
from django.db.models import Q
from annonces.models import Annonce, State, Delegation, Jurisdiction
from difflib import SequenceMatcher
from images.models import Image
import re
from historique.models import Historique
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from authentification.authentication import JWTAuthentication
# Create your views here.

def get_state_and_jurisdictions_by_delegation(delegation_name):
    try:
        # Get the delegation by name
        delegation = Delegation.objects.get(name=delegation_name)
        # Get the state related to the delegation
        state_name = delegation.state.name
        # Get all jurisdictions related to the state
        jurisdictions = Jurisdiction.objects.filter(delegation__state=delegation.state).values_list('name', flat=True)
        return state_name, list(jurisdictions)
    
    except Delegation.DoesNotExist:
        return None, None  # If no such delegation found

# Function to get delegation name and state name for a given jurisdiction
def get_delegation_and_state_by_jurisdiction(jurisdiction_name):
    try:
        # Get the jurisdiction by name
        jurisdiction = Jurisdiction.objects.get(name=jurisdiction_name)
        # Get the related delegation and state
        delegation_name = jurisdiction.delegation.name
        state_name = jurisdiction.delegation.state.name
        
        return delegation_name, state_name
    
    except Jurisdiction.DoesNotExist:
        return None, None  

def process_input_size(input_string):
    input_string = input_string.strip().lower()
    input_string = re.sub(r'\s+', '', input_string)  
    input_string = re.sub(r'[^s0-9\+\-\s]', '', input_string) 
    if input_string.startswith('s'):
        input_string = 's' + re.sub(r'^s+', '', input_string[1:])

    pattern = r'^s[\+\-]?\d+$'  
    match = re.match(pattern, input_string)
    if match:
        numeric_part = match.group(0)[1:]  # Remove the 's'
        if numeric_part == '0':
            return "s+0"
        else:
            # Ensure the correct sign is used
            if numeric_part.startswith('+') or numeric_part.startswith('-'):
                return f"s{numeric_part}"
            else:
                return f"s+{numeric_part}" 
    else:
        return ''

# String matching based on similarity for Types
def match_strings_similar_for_types(word, list_of_strings, threshold=0.8):
    word = word.lower()

    for string in list_of_strings:
        for part in string.lower().split():
            similarity = SequenceMatcher(None, word, part).ratio()
            if similarity >= threshold:
                return string  # Return the full original string
    return False

# String matching based on similarity
def match_strings_similar(str1, str2, threshold=0.8):
    similarity = SequenceMatcher(None, str1, str2).ratio()
    if similarity >= threshold:
        return str2
    else:
        return False
    
# Get matching location name
def get_location_name(word, location_list):
    for element in location_list:
        # Access the first item of the tuple
        element_name = element[0] if isinstance(element, tuple) else element
        if match_strings_similar(word.lower(), element_name.lower(), threshold=0.8) is not False:
            return element_name
    return ''

# Function to detect features from a query
def detect_features(query,types_list,states_list,delegations_list,jurisdictions_list):
    features = {}
    features['search'] = query
    query=filter_input(query)
    # Match fields based on assumptions or known patterns
    for item in query:
        if item.isdigit():  
            features['price'] = item
            print({"features['price']": features['price']})
            continue  
        else:
            # Check and assign each feature if the item corresponds to it
            if 'type' not in features and match_strings_similar_for_types(item, types_list):  # Check if it's a valid type
                features['type'] = match_strings_similar_for_types(item, types_list)
                print({"features['type']": features['type']})
                continue  
                
            if 'size' not in features and process_input_size(item):  # Only set 'size' if it's not set already
                features['size'] = process_input_size(item)
                print({"features['size']": features['size']})
                continue 
                
            if 'state' not in features and get_location_name(item, states_list):  # Check if it's a valid state
                features['state'] = get_location_name(item, states_list)
                print({"features['state']": features['state']})
                continue  
            
            if 'delegation' not in features and 'jurisdiction' not in features and get_location_name(item, delegations_list):  # Check if it's a valid delegation
                features['delegation'] = get_location_name(item, delegations_list)
                continue  
            
            if 'jurisdiction' not in features and get_location_name(item, jurisdictions_list):  # Check if it's a valid jurisdiction
                features['jurisdiction'] = get_location_name(item, jurisdictions_list)
                continue
            
            # Check for title
            #if 'title' not in features:  # Add title feature
                #features['title'] = item
                #print({"features['title']": features['title']})
    return features
    
@api_view(['POST'])
@permission_classes([AllowAny])
def search_query(request):
    """add search query by user"""
    list_types = []
    list_states = []
    list_delegations = []
    list_jurisdictions = []
    data = request.body.decode('utf-8')
    data = json.loads(data)
    types = Type.objects.all()
    states = State.objects.all()
    delegations = Delegation.objects.all()
    jurisdictions = Jurisdiction.objects.all()
    for type in types:
        list_types.append(type.name)
    for state in states:
        list_states.append(state.name)
    for delegation in delegations:
        list_delegations.append(delegation.name)
    for jurisdiction in jurisdictions:
        list_jurisdictions.append(jurisdiction.name)
    search_query_filter = filter_input(data['search_query'])
    for i, element in enumerate(search_query_filter):
        if match_strings_similar_for_types(element, list_types):
            search_query_filter[i] = match_strings_similar_for_types(element, list_types)

            
    data['search_query'] = ' '.join(search_query_filter)
    data['date_of_search'] = datetime.now().strftime("%Y-%m-%d")
    query_features = detect_features(data['search_query'],list_types,list_states,list_delegations,list_jurisdictions)
    if "user" in data.keys():
        if not Historique.objects.filter(
            search_query=data['search_query'],
            user=data['user']
        ).exists():
            historique_serializer = HistoriqueSerializer(data=data)
            if historique_serializer.is_valid():
                historique_serializer.save()
            else:
                return JsonResponse({'error': historique_serializer.errors}, status=400)
    # Extract search parameters
    jurisdiction = query_features.get('jurisdiction', None)
    state = query_features.get('state', None)
    delegation = query_features.get('delegation', None)
    size = query_features.get('size', None)
    price = query_features.get('price', None)
    type = query_features.get('type', None)
    
    # Build the query using Q objects for specific fields
    query = Q()
    # Check if all fields are empty or None (i.e., no filters provided)
    if not any([state, delegation, jurisdiction, size, type, price]):
        print("All filters are empty, returning empty list")
        # Return the results as JSON
        return JsonResponse({'data': []}, status=200)
    else:
        if state:
            query &= Q(state__name__icontains=state)
        
        if delegation:
            query &= Q(delegation__name__icontains=delegation)
            
        if jurisdiction:
            query &= Q(jurisdiction__name__icontains=jurisdiction)
        
        if size:
            query &= Q(size__icontains=size)
        
        if type:
            query &= Q(type__name__icontains=type)
            
        if price:
            query &= Q(price__icontains=price)
        
        # Filter Annonce objects based on the query
        annonces = Annonce.objects.filter(query)
        # Serialize the results into a list of dictionaries
        annonces_data = []
        for annonce in annonces:
            annonce_data = {
                'title': annonce.title,
                'description': annonce.description,
                'size': annonce.size,
                'price': annonce.price,
                'state': annonce.state.name,
                'delegation': annonce.delegation.name if annonce.delegation else '',
                'jurisdiction': annonce.jurisdiction.name if annonce.jurisdiction else '',
                'status': annonce.status,
                'type': annonce.type.name,
                'localisation': annonce.localisation,
                'date_posted': annonce.date_posted,
                'user_phone': annonce.phone,
                # 'user_phone': annonce.user.phone_number,
            }
            # Fetch images associated with the annonce
            images = Image.objects.filter(annonce_id=annonce.pk)
            annonce_data['images'] = [image.image_url for image in images]
            # if annonce.user:
            #     annonce_data['user_phone'] = annonce.user.phone_number
            annonces_data.append(annonce_data)
            
        # Return the results as JSON
        return JsonResponse({'data': annonces_data}, status=200)

@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def all_search_query(request):
    historiques_list = []
    historiques = Historique.objects.all()
    historiques_json = serializers.serialize('json', historiques)
    res = json.loads(historiques_json)
    for i in range(len(res)):
        res[i].pop('model')
        trust_id = res[i]['pk']
        res[i].pop('pk')
        res[i]['fields']['id'] = trust_id
        # user = User.objects.get(id=res[i]['fields']['user'])
        # res[i]['fields']['email'] = user.email
        historiques_list.append(res[i]['fields'])
    grouped_data = defaultdict(list)
    for item in historiques_list:
        grouped_data[item["user"]].append(item)

    # Convert back to a regular dictionary if needed
    grouped_data = dict(grouped_data)
    search_queries_by_user = get_search_queries_by_user(historiques_list)
    return JsonResponse({'historiques_list': search_queries_by_user}, status=200)

def get_search_queries_by_user(historiques_list):
    # Use defaultdict to group search queries by user ID
    result = defaultdict(list)
    # Iterate through the list
    for item in historiques_list:
        # Group search queries by user ID
        result[item["user"]].append(item["search_query"])
    
    # Convert defaultdict to a regular dictionary for the output
    return dict(result)
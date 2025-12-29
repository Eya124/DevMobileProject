import json
from django.shortcuts import render
from annonces.models import *
from images.models import Image
from django.core.paginator import Paginator
from datetime import datetime, date

# Create your views here.
def home(request):
    """Retrieve all annonces"""
    list_annonces = []
    list_images = []
    annonce_json = {}
    annonces = Annonce.objects.all()
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
        images = Image.objects.filter(annonce_id=annonce.pk)
        for image in images:
            list_images.append(image.image_url)
        annonce_json['images'] = list_images
        list_annonces.append(annonce_json)
        annonce_json = {}
        list_images = []
    
    # # Set the number of items per page
    # paginator = Paginator(list_annonces, 9)  # 9 items per page
    
    # # Get the page number from the request (default to 1 if not provided)
    # page_number = request.GET.get('page')
    # page_obj = paginator.get_page(page_number)
    
    # # Pass the page_obj to the template context
    # context = {'page_obj': page_obj}
    # return render(request, 'annonces/all_annonces.html',context)
    # Filter parameters from GET request
    title_filter = request.GET.get('title', '')
    state_filter = request.GET.get('state', '')
    delegation_filter = request.GET.get('delegation', '')
    jurisdiction_filter = request.GET.get('jurisdiction', '')
    price_min = request.GET.get('price_min', '')
    price_max = request.GET.get('price_max', '')
    date_posted_from = request.GET.get('date_posted_from', '')
    annonces = list_annonces
    # Apply filters
    if title_filter:
        annonces = [annonce for annonce in annonces if title_filter.lower() in annonce['title'].lower()]

    if state_filter:
        annonces = [annonce for annonce in annonces if state_filter.lower() in annonce['state'].lower()]

    if delegation_filter:
        annonces = [annonce for annonce in annonces if delegation_filter.lower() in annonce['delegation'].lower()]

    if jurisdiction_filter:
        annonces = [annonce for annonce in annonces if jurisdiction_filter.lower() in annonce['jurisdiction'].lower()]

    if price_min:
        try:
            price_min = float(price_min)
            annonces = [annonce for annonce in annonces if annonce['price'] >= price_min]
        except ValueError:
            pass

    if price_max:
        try:
            price_max = float(price_max)
            annonces = [annonce for annonce in annonces if annonce['price'] <= price_max]
        except ValueError:
            pass

    # Handle date filters
    if date_posted_from:
        date_posted_from = datetime.strptime(date_posted_from, '%Y-%m-%d').date()
        annonces = [annonce for annonce in annonces if annonce['date_posted'] >= date_posted_from]

    # Pagination
    paginator = Paginator(annonces, 9)  # 9 items per page
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    states = State.objects.all()
    delegations = Delegation.objects.all()
    jurisdictions = Jurisdiction.objects.all()
    all_annonces = Annonce.objects.all()
    annonces_with_coords = []

    for annonce in all_annonces:
        coords = STATE_COORDINATES.get(annonce.state.name)
        if coords:
            annonces_with_coords.append({
                'title': annonce.title,
                'description': annonce.description,
                'latitude': coords[0],
                'longitude': coords[1],
            })
    context = {
        'page_obj': page_obj,
        'title_filter': title_filter,
        'state_filter': state_filter,
        'delegation_filter': delegation_filter,
        'jurisdiction_filter': jurisdiction_filter,
        'price_min': price_min,
        'price_max': price_max,
        'date_posted_from': date_posted_from,
        'states':states,
        'delegations':delegations,
        'jurisdictions':jurisdictions,
        'annonces': annonces_with_coords
    }
    print({"annonces_with_coords":annonces_with_coords})
    return render(request, 'annonces/all_annonces.html', context)

from django.db.models import Count
from collections import Counter
def dashboard(request):
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
        
    # Convert the data to JSON format to pass to the template
    date_data = json.dumps({'labels': [str(date) for date in date_labels], 'counts': date_counts})
    price_data = json.dumps({'bins': sorted_labels, 'counts': sorted_values})
    state_data = json.dumps({'labels': state_labels, 'counts': state_counts})
    size_data = json.dumps({'labels': size_labels, 'counts': size_counts})
    
    # Render the template and pass the data
    return render(request, 'dashboard/dashboard.html', {
        'date_data': date_data,
        'price_data': price_data,
        'state_data': state_data,
        'size_data': size_data,
    })
    

def annonce_details(request, filter_value):
    # Example of filtering by size, price, or state
    filter_type = request.GET.get('filter_type', 'state')  # Default to state filter
    if filter_type == 'size':
        annonces = Annonce.objects.filter(size=filter_value)
    elif filter_type == 'price':
        # Filter annonces where price is between filter_value + 1 and filter_value + 99
        annonces = Annonce.objects.filter(price = int(filter_value))
    elif filter_type == 'state':
        state = State.objects.get(name=filter_value)
        annonces = Annonce.objects.filter(state=state.id)
    else:
        annonces = Annonce.objects.all()  # If no filter, show all
    list_annonces = []
    annonce_json = {}
    list_images = []
    for annonce in annonces:
        annonce_json['id'] = annonce.pk
        if annonce.user:
            annonce_json['user_id'] = annonce.user.pk
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
        list_annonces.append(annonce_json)
        annonce_json = {}
        list_images = []
    paginator = Paginator(list_annonces, 9)  # 9 items per page
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    # Pass the filtered annonces to the template
    return render(request, 'annonces/details.html', {'page_obj': page_obj})


STATE_COORDINATES = {
    "Tunis": (36.81897, 10.16579),
    "Ariana": (36.86654, 10.16472),
    "Ben Arous": (36.75306, 10.22172),
    "Manouba": (36.807, 10.0953),
    "Nabeul": (36.45196, 10.73513),
    "Zaghouan": (36.40211, 10.14292),
    "Bizerte": (37.27442, 9.87391),
    "Beja": (36.72564, 9.18169),
    "Jendouba": (36.50114, 8.77917),
    "Kef": (36.17424, 8.70487),
    "Siliana": (36.08496, 9.37082),
    "Kairouan": (35.67483, 10.10124),
    "Sousse": (35.82539, 10.63699),
    "Monastir": (35.77703, 10.82617),
    "Mahdia": (35.50473, 11.06222),
    "Sfax": (34.74056, 10.76028),
    "Gabes": (33.88146, 10.0982),
    "Medenine": (33.35495, 10.50548),
    "Tataouine": (32.92966, 10.45177),
    "Gafsa": (34.425, 8.78417),
    "Tozeur": (33.91968, 8.13352),
    "Kebili": (33.70439, 8.97346),
    "Douz": (33.45691, 9.02143),
    "Kasserine": (35.16758, 8.83651)
}

def map_view(request):
    annonces = Annonce.objects.all()
    annonces_with_coords = []

    for annonce in annonces:
        coords = STATE_COORDINATES.get(annonce.state.name)
        if coords:
            annonces_with_coords.append({
                'id': annonce.pk,
                'title': annonce.title,
                'description': annonce.description,
                'latitude': coords[0],
                'longitude': coords[1],
            })
    print(len(annonces_with_coords))
    return render(request, 'annonces/map.html', {'annonces': annonces_with_coords})
import os
import json
import re
import logging
import django
import pandas as pd
from datetime import datetime
from difflib import SequenceMatcher
from django.core.exceptions import ObjectDoesNotExist, MultipleObjectsReturned
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.feature_extraction.text import TfidfVectorizer
from django.core.mail import EmailMultiAlternatives
from django.conf import settings
import sys
# Add the project root directory to the Python path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ekrili.settings')
django.setup()

from annonces.models import Annonce, State, Delegation, Jurisdiction
from type.models import Type
from images.models import Image
from historique.function import all_search_query_func
from users.models import User

# Create logs directory if it doesn't exist
os.makedirs('logs', exist_ok=True)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/annonce_recommendation.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def remove_unsupported_chars(text):
    return re.sub(r'[^\x00-\x7F]+', '', text)

def extract_numbers(phone_number):
    if phone_number == '':
        return 0
    # Regular expression to match numbers after +216
    match = re.search(r"\+216(\d+)", phone_number)
    if match:
        return match.group(1)  # Return the captured numbers after +216
    else:
        return phone_number 

# Function to extract numeric price value from a string
def extract_numeric_price(price_str):
    # Use regex to extract digits from the price string
    match = re.search(r'\d+', price_str)
    return int(match.group(0)) if match else 0

##################### Helper Functions ##########################
def send_email_annonce_from_scrape(user, annonce):
    """Send email notification to user about relevant announcement."""
    try:
        # base_url = settings.BASE_URL 
        base_url = "http://localhost:5173"
        full_url = f"{base_url}/annonces/{annonce.pk}/details"
        subject = 'Relevant Announcement Based on Your Search ^^'
        text_message = f'Dear {user.first_name},'
        message = f"""
        <p>We are pleased to inform you that we have found an announcement that corresponds 
        to your recent search on our site. Please find the details below:</p>
        <p><strong>{annonce.title}</strong></p>
        <p>{annonce.description}</p>
        <p>You can view the full announcement at: <a href="{full_url}">{full_url}</a></p>
        <p>Best regards,</p>
        """
        
        msg = EmailMultiAlternatives(
            subject, 
            text_message, 
            settings.EMAIL_HOST_USER,
            [user.email]
        )
        msg.attach_alternative(message, "text/html")
        msg.send()
        logger.info(f"Email sent to {user.email} for annonce {annonce.pk}")
    except Exception as e:
        logger.error(f"Failed to send email to {user.email}: {e}", exc_info=True)

def match_strings_similar(str1, str2, threshold=0.8):
    """Calculate string similarity ratio."""
    return SequenceMatcher(None, str1.lower(), str2.lower()).ratio() >= threshold

def get_location_name(word, location_list):
    """Find matching location name from list."""
    for element in location_list:
        element_name = element[0] if isinstance(element, tuple) else element
        if match_strings_similar(word, element_name):
            return element_name
    return None

def process_input_size(input_string):
    """Standardize size input format."""
    if not input_string:
        return ''
        
    input_string = re.sub(r'\s+', '', input_string.lower())
    input_string = re.sub(r'[^s0-9\+\-]', '', input_string)
    
    if input_string.startswith('s'):
        input_string = 's' + re.sub(r'^s+', '', input_string[1:])
    
    pattern = r'^s[\+\-]?\d+$'
    if re.match(pattern, input_string):
        numeric_part = input_string[1:]
        if numeric_part == '0':
            return "s+0"
        elif numeric_part.startswith(('+', '-')):
            return f"s{numeric_part}"
        return f"s+{numeric_part}"
    return ''

def detect_features(query, types_list, states_list):
    """Extract features from search query."""
    features = {}
    for item in query:
        if item.isdigit():  
            features['price'] = item
            continue
            
        if 'type' not in features and (type_name := get_location_name(item, types_list)):
            features['type'] = type_name
            continue
            
        if 'size' not in features and (size := process_input_size(item)):
            features['size'] = size
            continue
            
        if 'state' not in features and (state_name := get_location_name(item, states_list)):
            features['state'] = state_name
            
    return features

def get_or_create_type(type_name):
    """Get or create Type object."""
    try:
        return Type.objects.get(name=type_name)
    except ObjectDoesNotExist:
        type_obj = Type.objects.create(name=type_name)
        logger.info(f"Created new Type: {type_name}")
        return type_obj
    except MultipleObjectsReturned:
        logger.warning(f"Multiple types found for name: {type_name}")
        return Type.objects.filter(name=type_name).first()

def get_location_object(location_name):
    """Get location object from State, Delegation or Jurisdiction."""
    try:
        return State.objects.get(name=location_name), None, None
    except ObjectDoesNotExist:
        try:
            return None, Delegation.objects.get(name=location_name), None
        except ObjectDoesNotExist:
            try:
                return None, None, Jurisdiction.objects.get(name=location_name)
            except ObjectDoesNotExist:
                logger.warning(f"Location not found: {location_name}")
                return None, None, None

###################################################################
# AnnonceRecommendationSystem class
class AnnonceRecommendationSystem:
    def __init__(self):
        self.vector_data = None
        self.qs_data = None
        self.tfidf = None
        self.tfidf_matrix = None
        
    FEATURE_WEIGHTS = {
        'state': 4,
        'type': 3,
        'size': 3,
        'price': 1
    }
    
    def load_data(self, vector_data, qs_data):
        """Load data for recommendation system."""
        self.vector_data = vector_data
        self.qs_data = qs_data
    
    def preprocess_data(self):
        """Prepare data for TF-IDF vectorization."""
        def apply_weight(feature, weight):
            return (self.vector_data[feature].fillna('') + ' ') * weight

        self.vector_data['combined_features'] = (
            self.vector_data['title'] + ' ' +
            apply_weight('size', self.FEATURE_WEIGHTS['size']) +
            apply_weight('state', self.FEATURE_WEIGHTS['state']) +
            apply_weight('type', self.FEATURE_WEIGHTS['type']) +
            apply_weight('price', self.FEATURE_WEIGHTS['price'])
        )
        
        self.tfidf = TfidfVectorizer(lowercase=True)
        self.tfidf_matrix = self.tfidf.fit_transform(self.vector_data['combined_features'])

    def preprocess_query(self, search_query):
        """Prepare search query for comparison."""
        
        # Get and ensure all values are strings, defaulting to empty if not found
        size = str(search_query.get('size', ''))
        state = str(search_query.get('state', ''))
        type_ = str(search_query.get('type', ''))
        price = str(search_query.get('price', ''))
        
        # Check if state in the query matches state in the annonce
        state_match = state == self.vector_data['state'].iloc[0]
        
        # Adjust weight for state matching (State has the most impact on similarity)
        state_weight = self.FEATURE_WEIGHTS['state'] if state_match else self.FEATURE_WEIGHTS['state'] / 2
        
        # Instead of multiplying by float, store the weighted score
        combined_interests = (
            (size + ' ') * int(self.FEATURE_WEIGHTS['size']) +  # Ensure integer multiplication
            (state + ' ') * int(state_weight) +  # Ensure integer multiplication
            (type_ + ' ') * int(self.FEATURE_WEIGHTS['type']) +  # Ensure integer multiplication
            (price + ' ') * int(self.FEATURE_WEIGHTS['price'])   # Ensure integer multiplication
        )
        
        return self.tfidf.transform([combined_interests])

    # def preprocess_query(self, search_query):
    #     """Prepare search query for comparison."""
    #     combined_interests = (
    #         (search_query.get('size', '') + ' ') * self.FEATURE_WEIGHTS['size'] +
    #         (search_query.get('state', '') + ' ') * self.FEATURE_WEIGHTS['state'] +
    #         (search_query.get('type', '') + ' ') * self.FEATURE_WEIGHTS['type'] +
    #         (search_query.get('price', '') + ' ') * self.FEATURE_WEIGHTS['price']
    #     )
    #     return self.tfidf.transform([combined_interests])

    def recommend(self, search_query):
        """Generate recommendations based on search query."""
        query_tfidf_matrix = self.preprocess_query(search_query)
        cosine_similarities = cosine_similarity(query_tfidf_matrix, self.tfidf_matrix)
        similarity_scores = cosine_similarities[0]
        
        # If the state does not match, heavily reduce the similarity score
        if search_query.get('state', '') != self.vector_data['state'].iloc[0]:
            similarity_scores *= 0.1  # Reduce the similarity score when states don't match

        return [
            (self.vector_data.iloc[i]['title'], similarity_scores[i] * 100)
            for i in similarity_scores.argsort()[::-1]
        ]

    # def recommend(self, search_query):
    #     """Generate recommendations based on search query."""
    #     query_tfidf_matrix = self.preprocess_query(search_query)
    #     cosine_similarities = cosine_similarity(query_tfidf_matrix, self.tfidf_matrix)
    #     similarity_scores = cosine_similarities[0]
        
    #     return [
    #         (self.vector_data.iloc[i]['title'], similarity_scores[i] * 100)
    #         for i in similarity_scores.argsort()[::-1]
    #     ]

# Main processing function
def process_folders(main_folder):
    """Process folders and import data into database."""
    logger.info(f"Starting processing of folder: {main_folder}")
    
    # Preload location and type data
    types_list = list(Type.objects.values_list('name', flat=True))
    states_list = list(State.objects.values_list('name', flat=True))
    
    for folder_name in os.listdir(main_folder):
        folder_path = os.path.join(main_folder, folder_name)
        
        if not os.path.isdir(folder_path):
            continue

        logger.info(f"Processing folder: {folder_name}")
        
        # Process images
        image_files = [
            os.path.join('scraping_folder_data', folder_name, f).replace('\\', '/')
            for f in os.listdir(folder_path) 
            if f.lower().endswith(('.jpg', '.jpeg', '.png'))
        ]
        
        json_file = os.path.join(folder_path, 'data.json')
        if not os.path.exists(json_file):
            logger.warning(f"No data.json found in {folder_name}")
            continue
            
        if Annonce.objects.filter(id_folder=folder_name).exists():
            logger.warning(f"Skipping existing annonce: {folder_name}")
            continue
            
        try:
            with open(json_file, 'r') as f:
                data = json.load(f)
                logger.debug(f"Data content: {json.dumps(data, indent=2)}")
                
                # Process location
                location_str = data.get('location', '')
                if not location_str:
                    raise ValueError("Missing location in data")
                    
                location_name = location_str.split(',')[0].strip()
                for prefix in ["La ", "Le "]:
                    if location_name.startswith(prefix):
                        location_name = location_name[len(prefix):]
                        break
                
                # Get location objects
                state, delegation, jurisdiction = get_location_object(location_name)
                if not any([state, delegation, jurisdiction]):
                    raise ValueError(f"Location not found: {location_name}")
                
                # Get or create type
                type_name = data.get('type')
                if not type_name:
                    raise ValueError("Missing type in data")
                type_obj = get_or_create_type(type_name)
                
                # Process other fields
                price = extract_numeric_price(data.get('price', '0'))
                phone = extract_numbers(data.get('phone_number', '0'))
                
                # Create Annonce
                annonce = Annonce.objects.create(
                    title=data.get('title', 'Sans Titre'),
                    description=remove_unsupported_chars(data.get('description', '')),
                    size=data.get('size', ''),
                    price=price,
                    state=state,
                    delegation=delegation,
                    jurisdiction=jurisdiction,
                    status=True,
                    type=type_obj,
                    localisation=location_str,
                    date_posted=datetime.now().date(),
                    phone=phone,
                    url=data.get('url', None),
                    id_folder=folder_name,
                )
                logger.info(f"Created Annonce ID: {annonce.id}")
                
                # Create images
                for image_file in image_files:
                    Image.objects.create(
                        image_url=f"/media/{image_file}",
                        annonce=annonce
                    )
                logger.info(f"Created {len(image_files)} images")
                
                # Prepare recommendation data
                vector_data = pd.DataFrame({
                    'title': [annonce.title],
                    'size': [annonce.size],
                    'state': [state.name if state else ''],
                    'type': [type_obj.name],
                    'price': [str(annonce.price)]
                })
                
                qs_data = all_search_query_func()
                recommendation_system = AnnonceRecommendationSystem()
                recommendation_system.load_data(vector_data, qs_data)
                recommendation_system.preprocess_data()
                
                # Process recommendations
                for user_id, user_queries in qs_data.items():
                    try:
                        user = User.objects.get(id=user_id)
                        for query in user_queries:
                            query_features = detect_features(query, types_list, states_list)
                            recommendations = recommendation_system.recommend(query_features)
                            
                            for _, score in recommendations:
                                logger.info(f"Annonce: {annonce.pk}, Similarity: {score:.2f}% for query_features: {query_features}")
                                logger.info(f"score: {score} for annonce {annonce.pk}")
                                if score > 50:  # Only send for good matches
                                    send_email_annonce_from_scrape(user, annonce)
                                    break
                    except Exception as e:
                        logger.error(f"Error processing user {user_id}: {e}")
                        
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in {json_file}: {e}")
        except Exception as e:
            logger.error(f"Error processing {folder_name}: {e}", exc_info=True)
        finally:
            logger.info('-' * 40)

if __name__ == '__main__':
    try:
        process_folders('media/scraping_folder_data')
        logger.info("Processing completed successfully")
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        raise
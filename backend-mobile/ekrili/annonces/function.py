from annonces.models import Annonce, State, Delegation, Jurisdiction
from difflib import SequenceMatcher
import re
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.feature_extraction.text import TfidfVectorizer

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
            return element_name.lower()
    return ''

def detect_features(query,types_list,states_list,delegations_list,jurisdictions_list):
    features = {}
    # Match fields based on assumptions or known patterns
    for item in query:
        if item.isdigit():  
            features['price'] = item
            continue  
        else:
            # Check and assign each feature if the item corresponds to it
            if 'type' not in features and get_location_name(item, types_list):  # Check if it's a valid type
                features['type'] = get_location_name(item, types_list)
                continue  
                
            if 'size' not in features and process_input_size(item):  # Only set 'size' if it's not set already
                features['size'] = process_input_size(item)
                continue 
                
            if 'state' not in features and get_location_name(item, states_list):  # Check if it's a valid state
                features['state'] = get_location_name(item, states_list)
                continue  
            
            if 'delegation' not in features and 'jurisdiction' not in features and get_location_name(item, delegations_list):  # Check if it's a valid delegation
                features['delegation'] = get_location_name(item, delegations_list)
                continue  
            
            if 'jurisdiction' not in features and get_location_name(item, jurisdictions_list):  # Check if it's a valid jurisdiction
                features['jurisdiction'] = get_location_name(item, jurisdictions_list)
                continue
            
    return features

# AnnonceRecommendationSystem class
class AnnonceRecommendationSystem:
    def __init__(self):
        self.vector_data = None
        self.qs_data = None
        self.tfidf = None
        self.tfidf_matrix = None
        self.states = None
        self.delegations = None
        self.jurisdictions = None
        self.types = None
        
    FEATURE_WEIGHTS = {
        'state': 4,        # High priority
        'delegation': 4,   # Medium priority
        'jurisdiction': 4, # Low priority
        'type': 1,         # Low priority
        'size': 3,         # Low priority
        'price': 1         # Low priority
    }
    
    def load_data(self, vector_data, qs_data):
        """Load the vector and query data along with additional metadata."""
        self.vector_data = vector_data
        self.qs_data = qs_data
    
    def preprocess_data(self):
        """Preprocess vector data for TF-IDF vectorization."""
        def apply_weight(feature, weight):
            return (self.vector_data[feature].fillna('').str.lower() + ' ') * weight

        self.vector_data['combined_features'] = (
            self.vector_data['title'] + ' ' +
            apply_weight('size', self.FEATURE_WEIGHTS['size']) +
            apply_weight('state', self.FEATURE_WEIGHTS['state']) +
            apply_weight('delegation', self.FEATURE_WEIGHTS['delegation']) +
            apply_weight('jurisdiction', self.FEATURE_WEIGHTS['jurisdiction']) +
            apply_weight('type', self.FEATURE_WEIGHTS['type']) +
            apply_weight('price', self.FEATURE_WEIGHTS['price'])
        )
        
        self.tfidf = TfidfVectorizer(lowercase=True)
        self.tfidf_matrix = self.tfidf.fit_transform(self.vector_data['combined_features'])

    def preprocess_query(self, search_query):
        """
        Preprocess a single search query to make it compatible with the TF-IDF matrix.
        Args:
            search_query (dict): A dictionary with the user's search query features.
        Returns:
            sparse_matrix: TF-IDF representation of the search query.
        """
        query_features = search_query
        # print({"search_query": search_query})
        
        # Extract and validate features, ensuring that None is replaced with empty strings
        size = query_features.get('size', '') or ''
        state = query_features.get('state', '') or ''
        delegation = query_features.get('delegation', '') or ''
        jurisdiction = query_features.get('jurisdiction', '') or ''
        type_ = query_features.get('type', '') or ''
        price = query_features.get('price', '') or ''

        # Combine features into a single string
        combined_interests = (
            (size + ' ') * self.FEATURE_WEIGHTS['size'] +
            (state + ' ') * self.FEATURE_WEIGHTS['state'] +
            (delegation + ' ') * self.FEATURE_WEIGHTS['delegation'] +
            (jurisdiction + ' ') * self.FEATURE_WEIGHTS['jurisdiction'] +
            (type_ + ' ') * self.FEATURE_WEIGHTS['type'] +
            (price + ' ') * self.FEATURE_WEIGHTS['price']
        )
        # print({"combined_interests":combined_interests})
        return self.tfidf.transform([combined_interests])

    def recommend(self, search_query):
        """
        Recommend annonces based on a search query using cosine similarity.
        Args:
            search_query (dict): The user's search query as a dictionary.
        Returns:
            list: Recommendations with similarity scores.
        """
        query_tfidf_matrix = self.preprocess_query(search_query)
        cosine_similarities = cosine_similarity(query_tfidf_matrix, self.tfidf_matrix)
        similarity_scores = cosine_similarities[0]
        recommended_annonces = [
            (self.vector_data.iloc[i]['title'], similarity_scores[i] * 100)
            for i in similarity_scores.argsort()[::-1]
        ]
        return recommended_annonces
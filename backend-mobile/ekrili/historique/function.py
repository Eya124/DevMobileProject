import Levenshtein
import re
import json
from historique.models import Historique
from django.core import serializers
from collections import defaultdict
from historique.function import *
from datetime import datetime, timedelta
from users.models import User

def is_fuzzy_match(word1, word2, threshold=0.8):
    # Get the similarity ratio between the two words
    ratio = Levenshtein.ratio(word1, word2)
    return ratio >= threshold

def filter_input(input_string):
    # Allow '+' symbol and remove all other non-alphanumeric characters
    clean_string = re.sub(r'[^\w\s+]', '', input_string)
    
    # Split the string into words by spaces and filter out empty words
    words = clean_string.split()
    return words

def is_date_more_than_x_days_old(date_str,X):
    """
    Check if the given date is more than 31 days earlier than today.
    
    Args:
        date_str (str): The date to compare in "YYYY-MM-DD" format.

    Returns:
        bool: True if the date is more than 31 days earlier than today, False otherwise.
    """
    if date_str:
        # Convert the input string to a datetime object
        date = datetime.strptime(date_str, "%Y-%m-%d")
        
        # Calculate the threshold date (31 days before today)
        threshold_date = datetime.now() - timedelta(days=X)
        
        # Compare the dates
        if date < threshold_date:
            return False
        else:
            return True
    else:
        return True
    
def all_search_query_func():
    historiques_list = []
    historiques = Historique.objects.all()
    historiques_json = serializers.serialize('json', historiques)
    res = json.loads(historiques_json)
    for i in range(len(res)):
        res[i].pop('model')
        trust_id = res[i]['pk']
        res[i].pop('pk')
        res[i]['fields']['id'] = trust_id
        user = User.objects.get(id=res[i]['fields']['user'])
        if is_date_more_than_x_days_old(res[i]['fields']['date_of_search'],31) and is_date_more_than_x_days_old(user.last_login.strftime("%Y-%m-%d"),61):
            historiques_list.append(res[i]['fields'])
    grouped_data = defaultdict(list)
    for item in historiques_list:
        grouped_data[item["user"]].append(item)

    # Convert back to a regular dictionary if needed
    grouped_data = dict(grouped_data)
    search_queries_by_user = get_search_queries_by_user(historiques_list)
    for key, values in search_queries_by_user.items():
        search_queries_by_user[key] = [value.split() for value in values]
    return search_queries_by_user

def get_search_queries_by_user(historiques_list):
    # Use defaultdict to group search queries by user ID
    result = defaultdict(list)
    
    # Iterate through the list
    for item in historiques_list:
        # Group search queries by user ID
        result[item["user"]].append(item["search_query"])
    
    # Convert defaultdict to a regular dictionary for the output
    return dict(result)
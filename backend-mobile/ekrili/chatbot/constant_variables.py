from dotenv import load_dotenv
import os
load_dotenv()
RECOMMENDATION=os.getenv("RECOMMENDATION")
API_KEY=os.getenv('API_KEY')
MODEL_NAME=os.getenv('MODEL_NAME')
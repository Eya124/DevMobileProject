
import requests
from chatbot.constant_variables import API_KEY,MODEL_NAME
from langchain.embeddings.base import Embeddings
import google.generativeai as genai
# client = genai.Client(api_key=API_KEY)

API_URL = "http://172.24.162.10:8111/annonces/all"


def fetch_annonces():
    """Fetch annonces from your existing API."""
    response = requests.get(API_URL)
    data = response.json()
    return data["list_annonces"]



genai.configure(api_key=API_KEY)
class GeminiLLM:
    """
    Wrapper class for interacting with the Gemini API as a callable LLM.

    This class initializes a Gemini client using the provided API key and allows
    LLM inference by simply calling the instance with a prompt string.
    """
    def __init__(self, api_key: str):
        """
        Initialize the Gemini client.

        :param api_key: (str) Your Google Gemini API key used for authentication.
        """
        self.client = genai.Client(api_key=api_key)

    def __call__(self, prompt: str) -> str:
        """
        Send a prompt to the Gemini model and return the generated response as text.

        :param prompt: (str) The input prompt to send to the model.
        :return: (str) The generated model output text.
        """
        return self.client.models.generate_content(
            model=MODEL_NAME,
            contents=prompt
        ).text
        
class GeminiEmbeddings(Embeddings):
    def embed_documents(self, texts):
        return [
            genai.embed_content(
                model="models/text-embedding-004",
                content=t,
                task_type="retrieval_document"
            )["embedding"]
            for t in texts
        ]

    def embed_query(self, text):
        return genai.embed_content(
            model="models/text-embedding-004",
            content=text,
            task_type="retrieval_query"
        )["embedding"]

from chatbot.constant_variables import API_KEY
from chatbot.utils import GeminiEmbeddings
import google.generativeai as genai
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import Chroma
genai.configure(api_key=API_KEY)

def json_to_documents(json_list):
    docs = []
    for item in json_list:
        
        # Construire un contenu riche pour les embeddings
        page_content = f"""
        ID: {item.get('id', '')}
        Title: {item.get('title', '')}
        Type: {item.get('type', '')}
        Description: {item.get('description', '')}
        Size: {item.get('size', '')}
        Price: {item.get('price', '')}
        Phone: {item.get('phone', '')}
        State: {item.get('state', '')}
        Delegation: {item.get('delegation', '')}
        Jurisdiction: {item.get('jurisdiction', '')}
        Status: {item.get('status', '')}
        Localisation: {item.get('localisation', '')}
        Date Posted: {item.get('date_posted', '')}
        Folder: {item.get('id_folder', '')}
        URL: {item.get('url', '')}
        """
        
        metadata = {k: v for k, v in item.items() if k not in ["description", "images"]}

        docs.append(Document(
            page_content=page_content.strip(),
            metadata=metadata
        ))
    
    return docs
def split_json_documents(documents):
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=1200,
        chunk_overlap=150
    )
    return splitter.split_documents(documents)

def process_json_documents(json_data):
    docs = json_to_documents(json_data)
    chunks = split_json_documents(docs)
    embeddings = GeminiEmbeddings()
    vector_store = Chroma.from_documents(
        documents=chunks,
        embedding=embeddings,
        persist_directory="chroma_db"
    )
    
    return vector_store
def get_retriever():
    embeddings = GeminiEmbeddings()
    vector_store = Chroma(
        persist_directory="chroma_db",
        embedding_function=embeddings
    )
    return vector_store.as_retriever(search_kwargs={"k": 4})

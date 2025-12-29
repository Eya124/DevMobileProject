import google.generativeai as genai
from chatbot.utils_retriever import get_retriever
from chatbot.constant_variables import API_KEY, MODEL_NAME
from langchain_core.prompts import PromptTemplate
from langchain_classic.chains.retrieval_qa.base import RetrievalQA
from langchain_google_genai import ChatGoogleGenerativeAI
genai.configure(api_key=API_KEY)


def get_custom_prompt():
    """
    Returns a PromptTemplate compatible with RetrievalQA.
    - context: retrieved documents from the retriever
    - question: the user query
    """
    template = """
Tu es un assistant spécialisé dans les annonces immobilières.

CONTEXTE (liste d'annonces) :
{context}

QUESTION DE L'UTILISATEUR :
{question}

Ta mission :
1. Comprendre la question de l'utilisateur.
2. Rechercher dans le CONTEXTE les annonces qui correspondent au besoin exprimé.
3. Produire une réponse sous forme de paragraphe clair et naturel.
4. Le paragraphe doit uniquement décrire les annonces trouvées, en résumant leurs informations importantes :
   - type du bien
   - localisation
   - taille (ex : S+1, S+2…)
   - prix
   - état ou caractéristiques notables
   - description utile
   - date de publication
   - lien de l’annonce
5. Ne pas inventer d'informations qui ne figurent pas dans le contexte.
6. Ne pas fournir d’analyse ou de recommandations : seulement un résumé fidèle des annonces retrouvées.

"""
    return PromptTemplate(
        input_variables=["context", "question"],
        template=template
    )
    
def generate_response(question:str)->str:
    llm = ChatGoogleGenerativeAI(
        model=MODEL_NAME,   # best for RAG
        temperature=0.2,
        streaming=True,
        api_key=API_KEY
    )

    retriever = get_retriever()
    prompt =get_custom_prompt()
    print({"question":question})
    # Build RAG chain
    chain = RetrievalQA.from_chain_type(
        llm=llm,
        retriever=retriever,
        chain_type="stuff",
        chain_type_kwargs={"prompt": prompt}
    )
    result = chain.run(question)
    return result
    




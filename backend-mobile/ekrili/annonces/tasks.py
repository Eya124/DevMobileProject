from celery import shared_task
from django.conf import settings
from django.core.mail import EmailMultiAlternatives
import pandas as pd
from type.models import Type
from annonces.models import Annonce, State, Delegation, Jurisdiction
from historique.function import all_search_query_func
from annonces.function import AnnonceRecommendationSystem, detect_features
from users.models import User
import logging
logger = logging.getLogger('celery')

def send_email_annonce(user,annonce,search_resultat):
    base_url = settings.BASE_URL 
    front_url = settings.FRONT_URL 
    full_url = f"{front_url}/annonces/{annonce.id}/details"
    subject = 'Annonce pertinente basée sur votre recherche ^^'
    text_message = f'Cher/Chère {user.first_name},'
    message = (
        "<div style='text-align:center;'>"
        f"<img src='{front_url}/images/logo_ekri.png' alt='Logo' style='max-width:100px;'/>"  # Ajoutez l'URL du logo ici
        f"<p>Nous avons le plaisir de vous informer que nous avons trouvé une annonce correspondant à votre recherche <b>< {search_resultat} > </b> récente sur notre site. Veuillez trouver les détails ci-dessous :</p>"
        f"<p>Titre: {annonce.title}</p>"
        f"<p>Description: {annonce.description}</p>"
        f"<p>Vous pouvez consulter l’annonce complète à l’adresse suivante : {full_url}</p>"
        f"<p>Si vous avez des questions ou besoin d’aide supplémentaire, n’hésitez pas à nous contacter.</p>"
        "<p>Pour toute question ou assistance, vous pouvez nous contacter à l'adresse suivante : contact@exemple.com ou par téléphone au +123 456 7890</p>"
        "</div>"
        f"<p>Cordialement,</p>"
    )
    recipient_list = [user.email]
    from_email = settings.EMAIL_HOST_USER 
    msg = EmailMultiAlternatives(subject, text_message, from_email, recipient_list)
    msg.attach_alternative(message, "text/html")
    msg.send()
    
@shared_task
def recommend_annonce_from_celery(annonce_id):
    """
    This function performs the trait after the annonce is created or updated.
    Example actions: sending a notification, logging, etc.
    """
    logger.info(f"Processing recommendation for Annonce ID: {annonce_id}")
    try:
        annonce = Annonce.objects.get(id=annonce_id)
        print(f"Announce {annonce.pk} has been created or update successfully.")
        vector_data = pd.DataFrame({
            'title': [annonce.title],
            'size': [annonce.size],
            'state': [annonce.state.name],
            'delegation': [annonce.delegation.name] if annonce.delegation else '',
            'jurisdiction': [annonce.jurisdiction.name] if annonce.jurisdiction else '',
            'type': [annonce.type.name],
            'price': [str(annonce.price)]
        })
        list_types = []
        list_states = []
        list_delegations = []
        list_jurisdictions = []
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
            
        qs_data = all_search_query_func()
        
        recommendation_system = AnnonceRecommendationSystem()
        recommendation_system.load_data(vector_data, qs_data)
        recommendation_system.preprocess_data()
        for user_id, user_queries in qs_data.items():
            print(f"Recommendations for User {user_id}:")
            for query in user_queries:
                query_features = detect_features(query, list_types,list_states, list_delegations, list_jurisdictions)
                result = ' '.join(value for value in query_features.values())
                # print({"query_features":query_features})
                recommendations = recommendation_system.recommend(query_features)
                for annonce_, score in recommendations:
                    print(f"Annonce: {annonce_}, Similarity: {score:.2f}%")
                    if score > 50:
                        user = User.objects.get(id=user_id)
                        send_email_annonce(user,annonce,result)
                        logger.info(f"Successfully processed recommendation for Annonce ID: {annonce_id}")
    except Exception as e:
        logger.error(f"Error processing recommendation for Annonce ID {annonce_id}: {str(e)}", exc_info=True)
        raise e
# Envoyer les notifications (étape suivante)
L'appli enregistre déjà le "token" de chaque téléphone dans la table device_tokens.
Pour envoyer une notif quand un message arrive, il faut un petit code serveur (gratuit) :
une Edge Function Supabase déclenchée par un Database Webhook sur l'INSERT dans `messages`.
Elle lit les tokens des autres participants (pas l'expéditeur) et appelle
l'API FCM HTTP v1 avec la clé de compte de service Firebase (stockée dans les secrets Supabase,
jamais dans l'appli). Titre : "Pseudo - Nom du groupe", corps : texte ou 📷 Photo / 🎥 Vidéo / 🎤 Vocal / 📄 Document.

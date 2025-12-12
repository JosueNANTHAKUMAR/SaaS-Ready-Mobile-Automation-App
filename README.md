# Mobile App Epitech (AREA)

Application mobile cross-platform pour la gestion de la vie étudiante et l'automatisation de tâches (Action-Reaction).

## 📱 Fonctionnalités
- **Authentification**: Connexion sécurisée.
- **Gestion des Services**: Connexion à divers services tiers (Google, GitHub, Spotify, etc.).
- **Création d'AREA**: Définition de triggers (déclencheurs) et d'actions.
- **Dashboard**: Vue d'ensemble des automatisations actives.

## 🛠 Stack Technique
- **Mobile**: Flutter, Dart
- **Backend**: Python
- **Infrastructure**: Docker, Docker Compose

## 🚀 Installation

### Prérequis
- Flutter SDK
- Docker & Docker Compose

### Lancement
1. Cloner le repo :
\`\`\`bash
git clone https://github.com/JosueNANTHAN/mobile-app-epitech.git
\`\`\`

2. Lancer les services (Backend & DB) :
\`\`\`bash
docker-compose up -d --build
\`\`\`

3. Lancer l'application mobile :
\`\`\`bash
cd services/web/mobile/gamestore
flutter pub get
flutter run
\`\`\`

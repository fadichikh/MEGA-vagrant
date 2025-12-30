Professional README for the Mega TP project This document supersedes the original README provided in the repository. It is intended for publication on GitHub and aims to clearly present the objectives, architecture, prerequisites, usage instructions and potential improvements of the project. Feel free to adapt the wording and structure to suit your needs and to translate it into English if you target an international audience. -->
Mega TP – Infrastructure Haute Disponibilité & DevOps





Présentation

Ce dépôt contient le code et la documentation pour un TP d’administration de systèmes répartis. L’objectif est de déployer automatiquement, via Vagrant et Ansible, une infrastructure virtuelle complète réunissant :

un cluster haute disponibilité (HA) basé sur Pacemaker/Corosync, capable de basculer automatiquement une adresse IP virtuelle (VIP) et des services critiques (Nginx, Samba) en cas de panne ;

un serveur Ubuntu jouant le rôle de contrôleur Ansible et de superviseur Zabbix ;

un contrôleur de domaine Active Directory sous Windows Server ;

des règles de durcissement pour les machines Linux et Windows ;

un système de supervision des ressources et des services.

Le résultat final est une plateforme d’entreprise fictive, entièrement déployée et configurée à l’aide d’outils d’Infrastructure as Code (IaC), démontrant des pratiques DevOps et des mécanismes de résilience.

Table des matières

Architecture

Pré-requis

Installation et mise en route

Détails des rôles Ansible

Personnalisation

Améliorations possibles

Contribuer

Licence

Architecture

L’architecture se déploie sur un réseau privé 192.168.50.0/24 et se compose des machines suivantes :

Hôte	OS	Adresse IP	Rôle principal
Admin	Ubuntu Server 22	192.168.50.10	Contrôleur Ansible, serveur Zabbix
Node01	AlmaLinux 9	192.168.50.20	Nœud du cluster HA (Nginx + Samba)
Node02	AlmaLinux 9	192.168.50.21	Nœud du cluster HA (Nginx + Samba)
WinSrv	Windows Server 2019	192.168.50.30	Contrôleur de domaine Active Directory
VIP	Virtuelle	192.168.50.100	IP flottante basculant entre Node01 et Node02

Un diagramme est disponible dans le dossier Docs/architecture.png et résume les flux (SSH, WinRM, Corosync, Zabbix) entre les machines. Le cluster est configuré en mode actif/passif : la VIP et les services associés (HTTP/partage Samba) basculent automatiquement sur l’autre nœud en cas de défaillance.

Pré-requis

Pour lancer ce TP dans de bonnes conditions, vous devez disposer :

D’un hyperviseur supporté par Vagrant : VMware Workstation (configuré dans le Vagrantfile) ou VirtualBox (adaptez le provider si nécessaire).

De Vagrant installé sur votre machine hôte. Sur Windows, assurez-vous que l’extension VMware pour Vagrant est activée si vous utilisez VMware.

D’une connexion Internet pour télécharger les images et les dépendances au premier lancement.

D’un environnement disposant d’au moins 12 Go de RAM et de 30 Go de disque libre, car les images Windows sont volumineuses.

Installation et mise en route

Cloner le dépôt puis lancer l’infrastructure :

git clone https://github.com/<fadichikh>/Mega_TP.git
cd Mega_TP
vagrant up


Cette commande instancie les quatre machines virtuelles et déclenche automatiquement les playbooks Ansible. Le script scripts/setup_admin.sh se charge d’installer Ansible et de générer une clé SSH pour l’utilisateur vagrant. La clé publique est copiée dans keys/id_rsa.pub afin d’être injectée dans les nœuds Linux pour l’authentification sans mot de passe.

Une fois le déploiement terminé, vous pouvez accéder aux services suivants :

Service	URL/chemin	Identifiants par défaut
Site Web (HA)	http://192.168.50.100	Accès public
Zabbix Frontend	http://192.168.50.10/zabbix	Login : Admin / Mot de passe : zabbix
Partage Samba	\\192.168.50.100\partage	Accès invité ou via le domaine

Pour administrer les machines, utilisez vagrant ssh Admin, vagrant ssh Node01, etc. Sur Windows, la communication se fait via WinRM et le rôle Ansible dédié configure la promotion en contrôleur de domaine.

Détails des rôles Ansible

Les playbooks sont organisés par rôles dans le dossier ansible/roles :

ha_cluster : installe Pacemaker, Corosync et PCS, active le dépôt HighAvailability, authentifie les nœuds, crée le cluster, configure la VIP et désactive STONITH/quorum pour un labo à deux nœuds. Les services Nginx et Samba sont installés mais la création des ressources correspondantes n’est pas automatisée (à compléter si nécessaire).

security : applique un durcissement de base sur les nœuds Linux : désactivation de l’accès SSH root, ouverture des ports essentiels via firewalld (ssh, http, https, high‑availability), activation des mises à jour automatiques via dnf-automatic.

windows : déploie le rôle Active Directory DS, promeut le serveur Windows en tant que contrôleur de domaine du domaine lab.local, redémarre la machine et applique une politique de mot de passe renforcée (longueur minimale de 12 caractères).

zabbix : installe le serveur et l’agent Zabbix sur l’hôte Admin, ainsi que MySQL et Nginx ; démarre les services nécessaires. Les nœuds du cluster ne déploient pas l’agent Zabbix par défaut – ajoutez un rôle supplémentaire pour les superviser.

Le fichier ansible/site.yml orchestre l’exécution : il met à jour /etc/hosts sur toutes les machines, configure le cluster sur les nœuds, déploie Zabbix sur l’admin, puis configure le serveur Windows.

Personnalisation

Plusieurs paramètres peuvent (et devraient) être adaptés :

Provider Vagrant : le fichier Vagrantfile cible VMware ; pour utiliser VirtualBox, remplacez la section config.vm.provider "vmware_desktop" par config.vm.provider "virtualbox" et supprimez les options spécifiques à VMware.

Mots de passe : la valeur hacluster_password utilisée pour l’utilisateur hacluster est codée en clair et n’est pas sécurisée. Modifiez‑la dans le rôle ha_cluster et envisagez d’utiliser un hash généré (password_hash('sha512')). Même remarque pour les mots de passe Windows.

Ressources Pacemaker : la création des ressources Nginx et Samba n’est pas incluse dans le rôle ha_cluster. Pour automatiser la bascule de ces services, ajoutez des tâches qui invoquent pcs resource create pour nginx et smb, puis regroupez‑les avec la VIP.

Supervision des nœuds : si vous souhaitez superviser Node01 et Node02, ajoutez un rôle zabbix_agent qui installe l’agent Zabbix sur ces machines et configure l’adresse du serveur (192.168.50.10).

Nom du domaine : par défaut, le domaine Active Directory est lab.local. Modifiez‑le dans le rôle windows si besoin.

Améliorations possibles

Le projet est fonctionnel pour un laboratoire mais plusieurs améliorations sont envisageables :

Sécurité renforcée : forcer l’authentification par clé SSH au lieu du mot de passe, activer SELinux en mode enforcing, configurer fail2ban, restreindre davantage les ports ouverts.

Automatisation de Samba et Nginx : créer des ressources Pacemaker pour les services Nginx et Samba afin d’assurer une bascule automatique avec la VIP. Ajouter un partage Samba configuré via Ansible.

Supervision avancée : installer la base de données Zabbix sur un serveur dédié, utiliser HTTPS pour l’interface Zabbix, créer des templates personnalisés, configurer des alertes e‑mail.

CI/CD : intégrer le dépôt à un pipeline CI (GitHub Actions, GitLab CI…) pour tester les playbooks et valider l’infrastructure avec Molecule.

Contribuer

Les contributions sont les bienvenues ! Vous pouvez signaler des bugs, proposer des améliorations ou soumettre des pull requests. N’oubliez pas d’adapter la documentation en conséquence.

Fork le projet et clonez votre copie :

git clone https://github.com/<fadichikh>/Mega_TP.git
cd Mega_TP


Créez une branche pour votre fonctionnalité :

git checkout -b ma‑nouvelle‑fonctionnalité


Apportez vos modifications, puis commitez :

git add .
git commit -m "Ajout de ma fonctionnalité"


Poussez la branche et ouvrez une pull request.

Licence

Ce projet est proposé sous licence MIT. Vous êtes libre de l’utiliser, de le modifier et de le distribuer tant que vous incluez la notice de licence originale.
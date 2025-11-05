# Instructions pour la configuration de l’infrastructure Kubernetes et Cloud SQL

## Création du compte

1. Chaque membre de l’équipe doit demander un **coupon** pour bénéficier d’un crédit de **50 USD** en remplissant le formulaire suivant : [Lien](https://vector.my.salesforce-sites.com/GCPEDU?cid=RUfENThK1siA59ihpXrLq8YOgfYNGhMPEmF5lOBQfmsUzqp7SYS1NfEp7b0z%2F1Ue/).  
   L’équipe disposera ainsi d’un **crédit total de 150 USD**.

2. Vérifiez votre compte en cliquant sur le lien de confirmation envoyé dans le deuxième courriel.  
   Vous recevrez ensuite un autre courriel pour **appliquer le coupon**.  
   Vous pouvez utiliser votre **adresse Gmail** pour en bénéficier.

3. Pour vérifier si les crédits ont bien été appliqués, rendez-vous sur la page suivante : [Lien](https://console.cloud.google.com/billing/credits).

---

## Configuration de Kubernetes

Dans cette étape, nous allons configurer un **cluster Kubernetes** avec les ressources minimales nécessaires pour déployer nos applications.

### 1. Création du projet

Tout d’abord, créez un **projet GCP** qui contiendra toutes les ressources liées au laboratoire.  
Pour ce faire, allez sur la [page principale](https://console.cloud.google.com/welcome).  
Cliquez sur le bouton situé à gauche de la barre de recherche (comme illustré ci-dessous), puis sélectionnez **New project**.  
Choisissez un nom pour le projet (ex. : `log680-a2025-project`) et cliquez sur **Create**.

![Create project](project_creation.png)

---

### 2. Installation de la CLI Google Cloud

Pour pouvoir créer un cluster depuis la ligne de commande, installez **gcloud** en suivant la [documentation officielle](https://docs.cloud.google.com/sdk/docs/install).

Vérifiez ensuite que l’installation a réussi :
```bash
gcloud --version
```

---

### 3. Authentification

Authentifiez-vous à votre compte GCP à l’aide de la commande suivante :
```bash
gcloud auth login
```
Une page web s’ouvrira pour vous permettre de vous connecter avec le **compte Gmail associé à votre projet GCP**.  
Une fois connecté, vous devriez voir le message suivant dans le terminal :
```
You are now logged in as [votre_compte_gmail].
```

---

### 4. Sélection du projet actif

Vérifiez que le **projet sélectionné** est bien celui que vous venez de créer.  
Utilisez l’**ID du projet** (et non son nom).  
Si nécessaire, sélectionnez-le avec la commande suivante :
```bash
gcloud config set project VOTRE_PROJECT_ID
```

---

### 5. Installation des dépendances

Installez les outils suivants :  
- **Helm** → [Documentation](https://helm.sh/docs/intro/install/)  
- **kubectl** → [Documentation](https://kubernetes.io/docs/tasks/tools/)

---

### 6. Création et configuration du cluster Kubernetes

Exécutez le script suivant :
```bash
sh ./create_k8s.sh [PROJECT] [REGION] [CLUSTER_NAME]
```

**Paramètres :**
- `PROJECT` : ID du projet (**obligatoire**)  
- `REGION` : région où le cluster sera créé (**optionnel**, défaut : `us-central1`)  
- `CLUSTER_NAME` : nom du cluster (**optionnel**, défaut : `log680-gcp-cluster`)  
<!-- - `SERVICE_ACCOUNT_NAME` : nom du compte de service associé au cluster (**optionnel**, défaut : `kubernetes-engine-developer`) -->

---

### 7. Vérification du cluster

Pour vérifier l’installation du cluster et récupérer l’adresse IP publique de votre ingress :
```bash
kubectl get svc -n ingress-nginx
```
Cette adresse IP servira de **point d’accès** aux applications hébergées dans le cluster.  
Notez qu’il peut falloir **quelques minutes** avant qu’elle s’affiche.

Votre fichier **kubeconfig** se trouve par défaut :
- sous **Linux/MacOS** : `~/.kube/config`
- sous **Windows** : `C:\Users\VotreNom\.kube\config`

---

### 8. Création du namespace Kubernetes

Créez le **namespace** de votre équipe en suivant les instructions du dépôt suivant :  
👉 [k8s-config-generator](https://github.com/aliarabat/k8s-config-generator).
Vous devez utiliser un fichier nommé `kubeconfig.b64`, qui vous permettra de gérer les ressources de votre namespace dans le cluster Kubernetes. Vous pouvez le stocker dans un secret GitHub Actions.

---

### 9. Configuration de Cloud SQL (PostgreSQL)

Créez et configurez une instance PostgreSQL sur Cloud SQL à l’aide du script suivant :
```bash
sh ./create_cloudsql.sh [PROJECT] [REGION] [INSTANCE_NAME] [USER_DB] [PASSWORD]
```

**Paramètres :**
- `PROJECT` : ID du projet (**obligatoire**)  
- `REGION` : région de création (**optionnel**, défaut : `us-central1`)  
- `INSTANCE_NAME` : nom de l’instance PostgreSQL (**optionnel**, défaut : `my-postgres`)  
- `USER_DB` : nom d’utilisateur de la base de données (**optionnel**, défaut : `log680user`)  
- `PASSWORD` : mot de passe de l’utilisateur (**optionnel**, défaut : `log680user`)

---

### 10. Création de la base de données et des utilisateurs

Créez la base de données, le nom d’utilisateur et le mot de passe nécessaires pour vos applications (`metrics-api` et `MobilitySoft`) en suivant les instructions du dépôt :  
👉 [postgresql-db-generator](https://github.com/aliarabat/postgresql-db-generator)

---

### 11. Sauvegarde des informations de connexion

Sauvegardez les identifiants de connexion à votre base de données dans un **secret Kubernetes** :

```bash
kubectl create secret generic db-credentials \
    --from-literal=POSTGRES_HOST=[Adresse privée de votre instance PostgreSQL] \
    --from-literal=POSTGRES_DB=[Nom de votre base de données] \
    --from-literal=POSTGRES_USER=[Nom d’utilisateur] \
    --from-literal=POSTGRES_PASSWORD=[Mot de passe] \
        -n [Nom de votre namespace Kubernetes] \
    --dry-run=client -o yaml | kubectl apply -f -
```

Le `NAMESPACE` peut être retrouvé à l’emplacement suivant : `k8s-config-generator/out/VotreGroupe/namespace.yaml`.

---

### Notes supplémentaires

- **Gestion du trafic externe**  
  Pour que vos applications puissent traiter le trafic provenant de l’extérieur, leurs `root_path` doivent commencer par le chemin spécifié dans le fichier *Ingress*. Par exemple, si l’Ingress de votre application `metrics-api` est exposé via `/team1/metrics-api`, alors le `root_path` de votre application doit commencer par ce segment :  
  ```python
  FastAPI(root_path="/team1/metrics-api")
  ```

- **Connexion à la base de données**  
  La connexion à la base de données se fait à l’aide d’une adresse IP **privée**, et non publique, puisque toutes les ressources sont hébergées dans le même réseau.

- **Utilisation des crédits Google Cloud**  
  Nous vous encourageons à utiliser judicieusement les crédits que Google vous a accordés.  
  Pour en tirer le meilleur parti, pensez à **supprimer le cluster Kubernetes et d'arrêter l’instance Cloud SQL** lorsque vous n’en avez pas besoin, afin de réduire vos coûts.  
  En pratique, il est souvent plus simple de supprimer le cluster Kubernetes (en utilisant `delete_k8s.sh`) et d’arrêter l’instance Cloud SQL (via l'interface graphique [GCP](https://console.cloud.google.com/sql/instances)), tout en conservant vos données dans la base de données, que vous pourrez réutiliser lors de la prochaine création de l’instance. N’hésitez pas à stocker les informations de connexion de votre base de données dans un secret après la recréation du cluster.

---

### ✅ Votre infrastructure est maintenant prête !

Vous disposez désormais d’un **cluster Kubernetes fonctionnel** et d’une **instance Cloud SQL PostgreSQL** prête à être utilisée par vos applications.
#!/bin/bash

PROJECT=$1
REGION=${2:-"us-central1"}
CLUSTER_NAME=${3:-"log680-gcp-cluster"}
SERVICE_ACCOUNT_NAME=${4:-"kubernetes-engine-developer"}


if [[ -z $PROJECT ]]; then
  echo "❌ Error: PROJECT_ID is required."
  exit 1
fi


gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
    --display-name="GKE Developer Service Account"


SERVICE_ACCOUNT_NAME="${SERVICE_ACCOUNT_NAME}@${PROJECT}.iam.gserviceaccount.com"


for ROLE in \
  roles/cloudsql.admin \
  roles/iam.serviceAccountCreator \
  roles/container.developer \
  roles/container.serviceAgent \
  roles/iam.serviceAccountAdmin \
  roles/iam.serviceAccountKeyAdmin
do
  gcloud projects add-iam-policy-binding $PROJECT \
    --member="serviceAccount:${SERVICE_ACCOUNT_NAME}" \
    --role="$ROLE"
done


gcloud beta container \
    --project \
        "$PROJECT" clusters create $CLUSTER_NAME \
    --zone \
        "$REGION-a" \
    --no-enable-basic-auth \
    --cluster-version \
        "1.33.5-gke.1080000" \
    --release-channel \
        "stable" \
    --machine-type \
        "e2-small" \
    --image-type \
        "COS_CONTAINERD" \
    --disk-type \
        "pd-standard" \
    --disk-size \
        "14GB" \
    --metadata \
    disable-legacy-endpoints=true \
    --service-account \
        "${SERVICE_ACCOUNT_NAME}" \
    --max-pods-per-node \
        "20" \
    --num-nodes \
        "2" \
    --logging=SYSTEM,WORKLOAD \
    --monitoring=SYSTEM,STORAGE,POD,DEPLOYMENT,STATEFULSET,DAEMONSET,HPA,JOBSET,CADVISOR,KUBELET,DCGM \
    --enable-ip-alias \
    --network \
        "projects/$PROJECT/global/networks/default" \
    --subnetwork \
        "projects/$PROJECT/regions/$REGION/subnetworks/default" \
    --no-enable-intra-node-visibility \
    --default-max-pods-per-node \
        "10" \
    --enable-dns-access \
    --enable-k8s-tokens-via-dns \
    --enable-k8s-certs-via-dns \
    --enable-ip-access \
    --security-posture=standard \
    --workload-vulnerability-scanning=disabled \
    --enable-google-cloud-access \
    --addons \
        HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
    --enable-autoupgrade \
    --enable-autorepair \
    --preemptible \
    --max-surge-upgrade \
        1 \
    --max-unavailable-upgrade \
        0 \
    --binauthz-evaluation-mode=DISABLED \
    --enable-managed-prometheus \
    --enable-shielded-nodes \
    --shielded-integrity-monitoring \
    --no-shielded-secure-boot \
    --node-locations \
        "$REGION-a"

# Enable Nginx
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  cloudresourcemanager.googleapis.com

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Create a namespace for the controller
kubectl create namespace ingress-nginx

# Install with external LoadBalancer service type
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.replicaCount=1

gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION-a --project $PROJECT

echo "Le cluster $CLUSTER_NAME a été bien créé avec succès dans le projet $PROJECT et région $REGION"
echo "Exécutez la commande 'kubectl get svc -n ingress-nginx' pour afficher @IP de votre ingress."
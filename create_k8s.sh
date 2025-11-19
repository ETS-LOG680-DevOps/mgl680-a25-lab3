set -e  # Stop on error

PROJECT=$1
REGION=${2:-"us-central1"}
ZONE="${REGION}-a"
CLUSTER_NAME=${3:-"log680-gcp-cluster"}

if [[ -z $PROJECT ]]; then
  echo "❌ Error: PROJECT_ID is required."
  exit 1
fi

echo "🔧 Enabling required APIs..."
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project "$PROJECT"

echo "🚀 Creating GKE cluster '$CLUSTER_NAME' in $ZONE ..."
gcloud beta container clusters create "$CLUSTER_NAME" \
  --project "$PROJECT" \
  --zone "$ZONE" \
  --no-enable-basic-auth \
  --cluster-version "1.33.5-gke.1162000" \
  --release-channel "stable" \
  --machine-type "e2-small" \
  --image-type "COS_CONTAINERD" \
  --disk-type "pd-standard" \
  --disk-size "14GB" \
  --metadata disable-legacy-endpoints=true \
  --max-pods-per-node "20" \
  --num-nodes "2" \
  --logging=SYSTEM,WORKLOAD \
  --monitoring=SYSTEM,STORAGE,POD,DEPLOYMENT,STATEFULSET,DAEMONSET,HPA,JOBSET,CADVISOR,KUBELET,DCGM \
  --enable-ip-alias \
  --network "projects/$PROJECT/global/networks/default" \
  --subnetwork "projects/$PROJECT/regions/$REGION/subnetworks/default" \
  --no-enable-intra-node-visibility \
  --default-max-pods-per-node "10" \
  --enable-dns-access \
  --enable-k8s-tokens-via-dns \
  --enable-k8s-certs-via-dns \
  --enable-ip-access \
  --security-posture=standard \
  --workload-vulnerability-scanning=disabled \
  --enable-google-cloud-access \
  --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
  --enable-autoupgrade \
  --enable-autorepair \
  --preemptible \
  --max-surge-upgrade 1 \
  --max-unavailable-upgrade 0 \
  --binauthz-evaluation-mode=DISABLED \
  --enable-managed-prometheus \
  --enable-shielded-nodes \
  --shielded-integrity-monitoring \
  --no-shielded-secure-boot \
  --node-locations "$ZONE"

echo "📡 Fetching cluster credentials..."
gcloud container clusters get-credentials "$CLUSTER_NAME" \
  --zone "$ZONE" \
  --project "$PROJECT"

echo "📦 Installing NGINX Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

kubectl create namespace ingress-nginx || true

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.replicaCount=1

echo "✅ Cluster '$CLUSTER_NAME' created successfully!"
echo "👉 Run: kubectl get svc -n ingress-nginx"
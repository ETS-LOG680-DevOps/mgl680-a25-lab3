PROJECT=$1
REGION=${2:-"us-central1"}
INSTANCE_NAME=${3:-"my-postgres"}

if [[ -z $PROJECT ]]; then
  echo "❌ Error: PROJECT_ID is required."
  exit 1
fi

# Set the current project
gcloud config set project $PROJECT

gcloud compute addresses delete google-managed-services-default --global

# kubectl delete secret generic postgres-instance-ip-secret

# Create PostgreSQL instance
gcloud sql instances delete $INSTANCE_NAME
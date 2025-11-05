PROJECT=$1
REGION=${2:-"us-central1"}
INSTANCE_NAME=${3:-"my-postgres"}
DB_VERSION=POSTGRES_15
DB_NAME=${4:-"log680db"}
USER_DB=${4:-"log680user"}
PASSWORD=${5:-"log680a2025"}

if [[ -z $PROJECT ]]; then
  echo "❌ Error: PROJECT_ID is required."
  exit 1
fi

# Set the current project
gcloud config set project $PROJECT

# Enable APIs
gcloud services enable sqladmin.googleapis.com \
  servicenetworking.googleapis.com \
  compute.googleapis.com \
  run.googleapis.com \
  iam.googleapis.com \
  --project=$PROJECT

# ---------------------------
# Reserve a private IP range for Google-managed services (VPC peering)
#    Using the default VPC (no new VPC created) and a /24 range.
# ---------------------------
gcloud compute addresses create google-managed-services-default \
    --global \
    --purpose=VPC_PEERING \
    --prefix-length=24 \
    --network=default \
    --project=$PROJECT

# ---------------------------
# Create the VPC peering (connect service networking)
# ---------------------------
gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --network=default \
    --ranges=google-managed-services-default \
    --project=$PROJECT

# Create PostgreSQL instance
gcloud sql instances create $INSTANCE_NAME \
  --database-version=$DB_VERSION \
  --tier=db-custom-2-8192 \
  --region=$REGION \
  --storage-size=10 \
  --network=projects/$PROJECT/global/networks/default \
  --assign-ip \
  --storage-auto-increase

# Create a user within the PostgreSQL instance
gcloud sql users set-password $USER_DB \
  --instance=$INSTANCE_NAME \
  --password=$PASSWORD

# Create a database within the PostgreSQL instance
gcloud sql databases create $DB_NAME --instance=$INSTANCE_NAME

gcloud sql instances describe $INSTANCE_NAME \
    --project=$PROJECT \
    --format="table(name,region,settings.tier,ipAddresses[].type,ipAddresses[].ipAddress)"

echo "Horray! L'instance $INSTANCE_NAME a été bien créée dans le project $PROJECT, dand la région $REGION."
echo "Horray! La base de données $DB_NAME, l'utilisateur $USER_DB, et le mot de passe $PASSWORD ont été créée avec succès."
#!/bin/bash

PROJECT=$1
REGION=${2:-"us-central1"}
CLUSTER_NAME=${3:-"log680-gcp-cluster"}
SERVICE_ACCOUNT_NAME=${4:-"kubernetes-engine-developer"}


if [[ -z $PROJECT ]]; then
  echo "❌ Error: PROJECT_ID is required."
  exit 1
fi

gcloud container clusters delete $CLUSTER_NAME --region $REGION-a

# SERVICE_ACCOUNT="${SERVICE_ACCOUNT_NAME}@${PROJECT}.iam.gserviceaccount.com"

# gcloud iam service-accounts delete $SERVICE_ACCOUNT

#!/bin/bash
set -e

export GCP_REGION=us-central1
export GCP_ZONE=us-central1-a
export GKE_CLUSTER_NAME=cosmocrat-web
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')

echo "GCP_REGION=$GCP_REGION"
echo "GKE_CLUSTER_NAME=$GKE_CLUSTER_NAME"
echo "PROJECT_ID=$PROJECT_ID"

gcloud iam service-accounts create kubeip-service-account --display-name "kubeIP"

gcloud iam roles create kubeip --project $PROJECT_ID --file /dev/stdin <<EOF
title: "kubeip"
description: "required permissions to run KubeIP"
stage: "GA"
includedPermissions:
- compute.addresses.list
- compute.instances.addAccessConfig
- compute.instances.deleteAccessConfig
- compute.instances.get
- compute.instances.list
- compute.projects.get
- container.clusters.get
- container.clusters.list
- resourcemanager.projects.get
- compute.subnetworks.useExternalIp
- compute.addresses.use
EOF

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:kubeip-service-account@$PROJECT_ID.iam.gserviceaccount.com --role projects/$PROJECT_ID/roles/kubeip


gcloud iam service-accounts keys create key.json \
--iam-account kubeip-service-account@$PROJECT_ID.iam.gserviceaccount.com

gcloud container clusters get-credentials $GKE_CLUSTER_NAME \
  --zone $GCP_ZONE \
  --project $PROJECT_ID

kubectl create secret generic kubeip-key --from-file=key.json

# Create 3 ips
for i in {1..3}; do gcloud compute addresses create kubeip-ip$i --project=$PROJECT_ID --region=us-central1; done

# Label them appropriately
for i in {1..3}; do gcloud compute addresses create kubeip-ip$i --project=$PROJECT_ID --region=us-central1; done


# Start the deployment:
kubectl apply -f deploy/.

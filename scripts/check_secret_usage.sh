#!/bin/bash

# Script to list the secrets under a namespace and then check if they are referred somewhere under the namespace. 
# This checks for the secrets under all deployments, statefulsets, cronjobs, daemonsets, jobs within the namespace.
# This by default skips through some of the secrets starting with trident, default and ontap due to the criticality of these secrets, However they can also be enabled.
# A condition would need to be added to check secrets under the trident resources.

SECRETS=$(kubectl get secrets -o json | jq -r '.items[] | select((.metadata.name | test("trident|default|ontap") | not )) | .metadata.name');
for secret in $SECRETS; do
   echo "-----------";
  echo "Secret Name: ${secret}";
 
  output=$(kubectl get deployment,statefulsets,cronjobs,daemonsets,jobs -o json | grep -A 2 -B 3 "$secret" 2>/dev/null) 
  if [[ -z "${output}" ]]; then
    echo "Secret not referred anywhere"
  else
    echo "secret referred"
    kubectl get deployments,statefulsets,daemonsets,jobs,cronjobs -o json | jq -r --arg secret "${secret}" '.items[] | select((any(.spec.template.spec.containers[]?; if .args? then .args[]? | contains($secret) else false end)) or (any(.spec.template.spec.volumes[]?; if .secret? then .secret.secretName? | contains($secret) else false end)) or (any(.spec.template.spec.volumes[]?; if .secret? then .secret.secretName? | contains($secret) else false end)) or (any(.spec.template.spec.containers[]?; if .env[]? then .env[]?.valueFrom.secretKeyRef.name? == $secret else false end))) | "Resource: Deployment/" + .metadata.name + ", Namespace: " + .metadata.namespace'
  fi
    echo "-----------";
done

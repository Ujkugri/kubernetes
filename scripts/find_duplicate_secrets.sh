#!/bin/bash

# Find duplicate secrets based on content across all namespaces

hashes=()
secrets_info=()

# Function to find the index of a hash in the 'hashes' array or return -1 if not found
find_index_of_hash() {
  local target_hash="$1"
  for i in "${!hashes[@]}"; do
    if [ "${hashes[$i]}" = "$target_hash" ]; then
      echo "$i"
      return
    fi
  done
  echo -1
}


# Currently only looks under the namespaces starting with clara, platform and harbor but can be edited as needed.
NAMESPACES=$(kubectl get namespaces -o json | jq -r '.items[] | select(.metadata.name | test("clara|platform|harbor")) | .metadata.name')
for namespace in $NAMESPACES; do
  SECRETS=$(kubectl get secrets -n "${namespace}" -o json | jq -r '.items[].metadata.name')

  for secret in $SECRETS; do
    SECRET_DATA=$(kubectl get secret -n "${namespace}" "$secret" -o json | jq -r 'select(.data != null) | .data | to_entries[] | .key+":"+.value' | sort | base64)
    SECRET_HASH="${SECRET_DATA}"

    index=$(find_index_of_hash "$SECRET_HASH")

    if [ $index -ge 0 ]; then

      echo "Duplicate secret found:"
      echo "  Namespace: '${namespace}', Secret: '${secret}'"
      echo "  '${secrets_info[$index]}'"
    else
      hashes+=("$SECRET_HASH")
      secrets_info+=("Namespace: '${namespace}', Secret: '${secret}'")
    fi
  done
done

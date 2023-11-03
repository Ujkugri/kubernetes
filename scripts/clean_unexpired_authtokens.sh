#!/bin/bash
# Check for unexpired auth tokens, if found deletes them.
rancher_exec="sudo docker exec -it rancher"
backup_tokens=(
       "kubectl get tokens -A -o yaml"
       )
backup_token_filename="tokens_$1_$(date +%F_T%T).yaml"

echo "Backing up tokens"

ssh $1 -t $rancher_exec $backup_tokens > $backup_token_filename

if [[ $? -eq 0 ]]; then
  echo "\n Backup of Kubernetes auth tokens from $1 saved to $backup_token_filename"
else
  echo "An error occurred during the backup"
fi

delete_unexp_tokens=(
    "kubectl delete tokens \$()"
    )

get_unexp_tokens=(
    "kubectl get token -A --no-headers -o go-template='{{range \$token := .items}}  {{ if (eq \$token.ttl 0)}} \
  {{.metadata.name}}  {{.userId}}  {{.ttl}}   {{.userPrincipal.displayName}}   {{.description}} {{\"\n\"}}{{end}}{{end}}' \
  | grep -v 'argocd\|checkmk\|Default Admin\|Monitoring' | awk '{print \$1}'" 
)
boolean_unexpired_auth_tokens_found=0
echo "\n Checking for unexpired auth tokens"
# check for unexpired auth tokens
if [ -z "$(ssh $1 -t $rancher_exec $get_unexp_tokens)" ]; then
  echo "No matching unexpired auth token found"
  exit 1
else
  echo " Unexpired tokens found!"
  boolean_unexpired_auth_tokens_found=1
fi

delete_unexp_tokens=(
    "kubectl delete tokens \$($rancher_exec $get_unexp_tokens)"
    )
if [ $boolean_unexpired_auth_tokens_found -eq 1 ]; then
    echo "\n Deleting unexpired auth tokens ..."

    ssh $1 -t $rancher_exec $delete_unexp_tokens 2>&1
    if [ -z "$(ssh $1 -t $rancher_exec $get_unexp_tokens)" ]; then
        echo "\n Some matching tokens found and deleted. "
    else
        echo "Deletion of tokens not successful"
    fi
else
    echo "No matching unexpired auth tokens found."
fi


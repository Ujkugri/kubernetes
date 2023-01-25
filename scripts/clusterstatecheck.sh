#! /usr/bin/env bash

# Colors
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'
magenta='\e[1;35m%s\e[0m\n'

##Variables
amount_pvc="$(kubectl get pvc --ignore-not-found=true -A --no-headers | wc -l | tr -d ' ')"
amount_pv="$(kubectl get pv --ignore-not-found=true --no-headers | wc -l | tr -d ' ')"
amount_issuers="$(kubectl get issuer,clusterissuers -A --ignore-not-found=true --no-headers | wc -l | tr -d ' ')"
amount_cert="$(kubectl get certificates.cert-manager.io -A --ignore-not-found=true --no-headers | wc -l | tr -d ' ')"
amount_tvol="$(kubectl get tvol -A --ignore-not-found=true --no-headers | wc -l | tr -d ' ')"

##### Pods and Containers
printf -- "\n$magenta" "Checking for Pods and Containers.."

if [[ $(kubectl get deploy -A --no-headers -o custom-columns="NAMESPACE:metadata.namespace,NAME:metadata.name,DESIRED:.spec.replicas,AVAILABLE:.status.availableReplicas" | awk ' $3!=$4 ') ]]; then
 printf -- "$red" "There are Deployments that have not the desired amount of ready Pods:"
 printf -- "$(kubectl get deploy -A -o custom-columns="NAMESPACE:metadata.namespace,NAME:metadata.name,DESIRED:.spec.replicas,AVAILABLE:.status.availableReplicas" | awk ' $3!=$4')\n" 
fi

if [[ $(kubectl get ds -A --no-headers | awk '$3!=$4 || $3!=$5 || $3!=$6 || $3!=$7') ]]; then
 printf -- "$red" "There are Daemonsets that have not the desired amount of ready Pods:"
 printf -- "$(kubectl get ds -A | awk '$3!=$4 || $3!=$5 || $3!=$6 || $3!=$7')\n"
fi

if [[ $(kubectl get sts -A --no-headers -o custom-columns="NAMESPACE:metadata.namespace,NAME:metadata.name,DESIRED:.spec.replicas,AVAILABLE:.status.availableReplicas" | awk ' $3!=$4 ') ]];then
 printf -- "$red" "There are Statefulsets that have not the desired amount of ready Pods:"
 printf -- "$(kubectl get sts -A -o custom-columns="NAMESPACE:metadata.namespace,NAME:metadata.name,DESIRED:.spec.replicas,AVAILABLE:.status.availableReplicas" | awk ' $3!=$4 ')\n"
fi

if [[ $(kubectl get pods -A -o custom-columns="NAMESPACE:metadata.namespace,POD:metadata.name,STATUS:status.phase,CONTAINERSTATUS:status.containerStatuses[*].ready" | grep -v Succeeded | grep false) ]]; then
 printf -- "$red" "The following pods have nonready containers:"
 printf --  "$(kubectl get pods -A -o custom-columns="NAMESPACE:metadata.namespace,POD:metadata.name,STATUS:status.phase,CONTAINERSTATUS:status.containerStatuses[*].ready" | head -n1 && kubectl get pods -A -o custom-columns="NAMESPACE:metadata.namespace,POD:metadata.name,STATUS:status.phase,CONTAINERSTATUS:status.containerStatuses[*].ready" | grep -v Succeeded | grep false)\n"
else 
 printf -- "${green}" "All containers are ready and all pods are running." 
fi


##### Volumes
printf -- "\n$magenta" "Checking for Volumes.."
if [ -z "$(kubectl get pvc -A --no-headers --ignore-not-found=true)" ]; then
 printf -- "${yellow}" "No Persistentvolumeclaims found! Should there be some Persistentvolumeclaims?"
fi
if [ "$(kubectl get pvc --no-headers -A -o custom-columns="NAMESPACE:metadata.namespace,CLAIMNAME:metadata.name,STATE:status.phase,VOLUME:.spec.volumeName" | grep -v Bound)" ]; then
  printf -- "$red" "There are not bound PersistentVolumeClaims!"
  printf --  "$(kubectl get pvc -A -o custom-columns="NAMESPACE:metadata.namespace,CLAIMNAME:metadata.name,STATE:status.phase,VOLUME:.spec.volumeName" | grep -v Bound)\n" 
else
  printf -- "${green}" "All Persistentvolumeclaims are bound. This Cluster has $amount_pvc Persistentvolumeclaims."
fi 

if [ -z "$(kubectl get pv --no-headers --ignore-not-found=true)" ]; then
 printf -- "${yellow}" "No Persistentvolumes found! Should there be some Persistentvolumes?"
fi
if [ "$(kubectl get pv --no-headers -o custom-columns="VOLUME:metadata.name,STATE:status.phase,CLAIM:.spec.claimRef.name" | grep -v Bound)" ]; then
 printf -- "$red" "There are not bound PersistentVolumes!"
 printf --  "$(kubectl get pv -o custom-columns="VOLUME:metadata.name,STATE:status.phase,CLAIM:.spec.claimRef.name" | grep -v Bound)\n"  
else
 printf -- "${green}" "All PersistentVolumes are bound. This Cluster has $amount_pv Persistentvolumes."
fi 

if [ "$(kubectl get crd | grep -c tvol)" -eq "0" ]; then
 printf --  "This Cluster does not have Tridentvolumes as CustomResource!" 
elif [ -z "$(kubectl get tvol -A --no-headers --ignore-not-found=true | wc -l)" ]; then
 printf -- "${yellow}" "No Tridentvolumes found! Should there be some Tridentvolumes?"
fi
if [ "$(kubectl get tvol -A --no-headers -o custom-columns="NAMESPACE:metadata.namespace,TRIDENTVOLUME:metadata.name,STATE:state" | grep -v online)" ] && [ "$(kubectl get crd | grep -c tvol)" ]; then
  printf -- "$red" "There are not online Tridentvolumes!"
  printf --  "$(kubectl get tvol -A -o custom-columns="NAMESPACE:metadata.namespace,TRIDENTVOLUME:metadata.name,STATE:state" | grep -v online)\n" 
else
  printf -- "${green}" "All TridentVolumes are online. This Cluster has ${amount_tvol} TridentVolumes."
fi 
if [ "$(kubectl get tbe -A --no-headers -o custom-columns="NAMESPACE:metadata.namespace,NAME:metadata.name,BACKEND:backendName,BACKEND UUID:backendUUID,STATE:state" | grep -v online)" ] && [ "$(kubectl get crd | grep -c tbc)" ]; then
  printf -- "$red" "The following Tridentbackends are missconfigured:"
  printf --  "$(kubectl get tbe -A -o custom-columns="NAMESPACE:metadata.namespace,NAME:metadata.name,BACKEND:backendName,BACKEND UUID:backendUUID,STATE:state" | grep -v online)\n"
else
  printf -- "${green}" "The Tridentbackups are all up and running." 
fi

if [ "$amount_pvc" != "$amount_pv" ] || ([ "$amount_pv" != "$amount_tvol" ] && [ "$amount_tvol" -ne "0" ]); then
  printf -- "$red" "Mismatch! The are $amount_pvc PersistentVolumeClaims, $amount_pv PersistentVolumes and $amount_tvol TridentVolumes."
else
  printf -- "${green}" "The amount of PersistentVolumeClaims, PersistentVolumes (and TridentVolumes) is equal!"
fi

##### Issuers
printf -- "\n$magenta" "Checking for (Cluster)Issuers.."
if [ -z "$(kubectl get issuer,clusterissuers -A --no-headers --ignore-not-found=true)" ]; then
 printf -- "${yellow}" "No (Cluster)Issuers found! Should there be some (Cluster)Issuers?"
fi
if [ "$(kubectl get issuers,clusterissuers --no-headers -A | grep -v True)" ]; then
  printf -- "$red" "The following (Cluster)Issuers are not ready:"
  printf -- "$(kubectl get issuers,clusterissuers -A | grep -v True)\n" 
else 
 printf -- "${green}" "All (Cluster)Issuers are ready. This Cluster has $amount_issuers (Cluster)Issuers."
fi 

##### Certificates
printf -- "\n$magenta" "Checking for Certificates.."
if [ "$(kubectl get crd | grep -c certificate)" = "0" ]; then
 printf -- "${yellow}" "This Cluster does not have Certificates as CustomResource! Should there the CustomResource Certificate?" 
elif [ -z "$(kubectl get certificates -A --no-headers --ignore-not-found=true | wc -l)" ]; then
 printf -- "$red" "No Certificates found!"
fi
if [ "$(kubectl get certificates.cert-manager.io -A --no-headers | grep -v True)" ]; then
  printf -- "$red" "The following Certifcates are not ready:"
  printf --  "$(kubectl get certificates.cert-manager.io -A | grep -v True)\n"
else
  printf -- "${green}" "All Certificatesa are valid. This Cluster has $amount_cert Certificates."
fi

##### Ingress
printf -- "\n$magenta" "Checking Ingresses.."
if [ "$(kubectl get svc -A | grep -i "pending")" ]; then
  printf -- "$red" "The following Loadbalancers are pending:"
  printf -- "$(kubectl get svc -A | grep -i "pending")\n"
else
 printf -- "$green" "There are no pending Loadbalancers."
fi

if [ "$(kubectl get ing -A -ojsonpath='{range .items[*]}{ .status.loadBalancer.ingress[*].ip }{"\n"}{end}' | grep -c -v "[1:9]")" -ne "0" ];then
  printf -- "$red" "The following Ingresses have no assigned Exteral-IP:"
  printf -- "$(kubectl get ing -A -o custom-columns="NAMESPACE:metadata.namespace,NAME:metadata.name,HOST:.spec.rules[*].host,ADDRESS:status.loadBalancer.ingress[*].ip" | head -n1 && kubectl get ing  -A -o custom-columns="NAMESPACE:metadata.namespace,NAME:metadata.name,HOST:.spec.rules[*].host,ADDRESS:status.loadBalancer.ingress[*].ip" | grep "<none>" )\n"
else
  printf -- "$green" "All Ingresses have an External-IP assigned."
fi

##### Hosts
printf -- "\n$magenta" "Checking Hosts.."
for host in $(kubectl get ing --no-headers -A --ignore-not-found=true | awk '{ system ("kubectl get ing " $2 " -n " $1  " -o jsonpath='\''{range .spec.rules[*]}{\"https://\"}{.host}{\"\\n\"}{end}'\''  ") }')
do
  if [ -z "$(curl -Is $host | head -n1)" ];then
     printf -- "$red" "ERROR! $host is not reachable!"
  else
     printf -- "$green" "SUCCESSFULLY connected to $host."
  fi
done

#! /usr/bin/env bash

for NAMESPACE in $(kubectl get ns --no-headers | awk '{print $1}')
do
   echo -e "Searching for tls-certs in Namespace $NAMESPACE\n"
   if [ $(kubectl get secrets --field-selector type=kubernetes.io/tls --no-headers -n $NAMESPACE 2> /dev/null | wc -l) -eq 0 ]; then
      echo -e "\t There are no tls-certs in this Namespace \n"
   else 
      for SECRET in $(kubectl get secrets --field-selector type=kubernetes.io/tls --no-headers -n $NAMESPACE | awk '{print $1}')
      do
         echo -e "\t The certifcate in the secret $SECRET is valid until $(kubectl get secret $SECRET -n $NAMESPACE -o jsonpath="{.data['tls\.crt']}" | base64 -d | openssl x509 -enddate -noout | cut -c 10-)" 
      done 2> /dev/null
      echo ""
   fi
done

#! /usr/bin/env bash

# Go over all namespaces in a cluster and check if they are empty of workloads and controller objects

# All workload objects to search for
# We only care for objects that actually are workload, so no cm,sa,secrets,and so on.
# and every namespace has a sa for example
OBJECTS=pods,jobs,cronjobs,deployments,daemonsets,statefulsets

echo "Empty Namespaces are:"
for NAMESPACE in $(kubectl get ns --no-headers | awk '{ print $1 }')
do 
  amount=$(kubectl get --no-headers ${OBJECTS} -n $NAMESPACE 2>/dev/null | wc -l)
  case $NAMESPACE in
    "kube-node-lease"|"default"|"kube-public"|"local") ;;
    *)  
         if [ $amount = 0 ]; then
           echo $NAMESPACE
         fi
   ;;
   esac
done

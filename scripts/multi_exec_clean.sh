#!/usr/bin/env bash

CONTEXT=$1
shift 1

kubectl --context=$CONTEXT get pod --all-namespaces --no-headers \
 -o custom-columns="NAMESPACE:.metadata.namespace,POD:.metadata.name,CONTAINER:.spec.containers[*].name" | \
awk -v context="$CONTEXT" -v cmd="$*" ‚{
  system("kubectl --context=" context " exec -it -n " $1 " " $2 " -c " $3 " -t -- " cmd)
}'


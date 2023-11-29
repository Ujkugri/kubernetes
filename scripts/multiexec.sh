#!/usr/bin/env bash

CONTEXT=$1
shift 1

for NAMESPACE in $(kubectl --context=$CONTEXT get ns --no-headers  | awk '{ print $1 }')
do
  for POD in $(kubectl --context=$CONTEXT get pod -n "$NAMESPACE"  --no-headers  | awk '{ print $1 }')
  do
    for CONTAINER in $(kubectl --context=$CONTEXT get pod "$POD" -n "$NAMESPACE" -o jsonpath='{ .spec.containers[*].name }')
    do
      kubectl --context=$CONTEXT exec -it -n "$NAMESPACE" "$POD" -c "$CONTAINER" -- $@
    done
  done
done

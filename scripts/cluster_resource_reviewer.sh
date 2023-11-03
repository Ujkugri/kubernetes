#!/bin/bash
# Reviews the resources utilized by the pods in the cluster.
# Provides the list of pods along with namespace and their resource utilization and requests and limits into a csv file. 

kubectl top pods --all-namespaces --no-headers | sort -k 4 -rh | while read -r namespace name cpu_usage mem_usage; do
  pod_json=$(kubectl get pod "$name" -n "$namespace" -o json)
  jq --argjson pod_json "$pod_json" --arg mem_usage "$mem_usage" --arg cpu_usage "$cpu_usage" -n '($pod_json | .spec.containers[] |  {name: .name, memory_request: .resources.requests.memory, memory_limit: .resources.limits.memory, cpu_request: .resources.requests.cpu, cpu_limit: .resources.limits.cpu}) +  {namespace: $pod_json.metadata.namespace, pod_name: $pod_json.metadata.name, memory_usage: $mem_usage, cpu_usage: $cpu_usage } ' | jq -r '.namespace +","+ .name +","+ .pod_name +","+ .memory_usage +","+  .memory_request +","+  .memory_limit +","+ .cpu_usage +","+ .cpu_request +","+ .cpu_limit'  >> $1.csv
done

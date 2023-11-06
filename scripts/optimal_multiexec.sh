#!/usr/bin/env bash
# Allows to run an exec in every container of over pod in a cluster.
#
# multiexec.sh KUBERNETESCONTEXT COMMAND
#
# The script either outputs the result of COMMAND or "OCI runtime
#  exec failed", which can mean two things:
# - The Container has no shell to execute a command.
# - The Container cannot execute the command, due to not having
#   the rights to execute this COMMAND or the corresponding
#   package is not installed in the container.

CONTEXT=$1
shift 1

kubectl --context=$CONTEXT get pod --all-namespaces --no-headers -o custom-columns="NAMESPACE:.metadata.namespace,POD:.metadata.name,CONTAINER:.spec.containers[*].name" | \
awk -v context="$CONTEXT" -v cmd="$*" '{
  printf "########################################################################################################################################\n"
  printf "Executing command %s into Container %s from Pod %s in the Namespace %s of the Cluster %s.\n", cmd, $3, $2, $1, context
  printf "########################################################################################################################################\n"
  cmd = "kubectl --context=" context " exec -it -n " $1 " " $2 " -c " $3 " -- " cmd
  system(cmd)
}'

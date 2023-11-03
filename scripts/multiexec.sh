#!/usr/bin/env bash
# Allows to run an exec in every container of over pod in a cluster.
#
# multiexec.sh KUBERNETESCONTEXT COMMAND
#
# The script either outputs the result of COMMAD or "OCI runtime
#  exec failed", which can mean two things:
# - The Container has no shell to execute a command.
# - The Container cannot execute the command, due to not having
#   the rights to execute this COMMNAD or the corrosponding
#   package is not installed in the container.

CONTEXT=$1
shift 1

for NAMESPACE in $(kubectl --context=$CONTEXT get ns --no-headers  | awk '{ print $1 }')
do
  for POD in $(kubectl --context=$CONTEXT get pod -n "$NAMESPACE"  --no-headers  | awk '{ print $1 }')
  do
    for CONTAINER in $(kubectl --context=$CONTEXT get pod "$POD" -n "$NAMESPACE" -o jsonpath='{ .spec.containers[*].name }')
    do
      cat <<EOF

########################################################################################################################################
Executing command $@ into Container $CONTAINER from Pod $POD in the Namespace $NAMESPACE of the Cluster $CONTEXT.
########################################################################################################################################
EOF
      kubectl --context=$CONTEXT exec -it -n "$NAMESPACE" "$POD" -c "$CONTAINER" -- $@
    done
  done
done

#! /bin/bash

function usage() {
    cat <<USAGE

    Usage: $0 [-s --status] [-c --context] [-a --all] [-n --namespace] [-f --force]

    Status are:
        ContainerCreating
        Error
        ErrImagePull
        Evicted
        ImagePullBackOff

    Options are:
        -h, --help            Display help for this script.
        -c, --context         Required. Kuberntes Context to operatore.
        -s, --status          Required. Wihich Pod Status to delete.
        -a, --all             Optional. Delete Pods over all Namespaces.
        -n, --namespace       Optional. Delete Pods over a specific Namespace.
        -f, --force           Optional. Trigger forcefull deletion.
USAGE
    exit 1
}

# if no arguments are provided, return usage function
if [ $# -eq 0 ]; then
    usage # run usage function
    exit 1
fi

# forcefull delete of pods?
force=
# over all namespaces
all_namespaces=false

while getopts "han:s:fc:" option; do
   case $option in
      h | -help)      usage ;;

      c | -context)                CONTEXT="$OPTARG" ;;

      s | -status)                 STATUS="$OPTARG"  ;;

      a | -all)                    all_namespaces=true ;;

      n | -namespace)              NAMESPACE="$OPTARG" ;;

      f | -force)                  force=" --force" ;;

      \?)            # Invalid option
                     echo "Error: Invalid option"
                     usage
                     ;;
   esac
done

# To make sure deletion happens eiter over all namespace or one specific
if ([ "$NAMESPACE" ] && [  $all_namespaces == true ])  || ([ -z "$NAMESPACE" ] && [  $all_namespaces == false ]) ; then
  echo "Either choose operation over all Namespaces (-a) or over a specific Namespace (-n NAMESPACE)!"

  exit 1
fi

# Main function for deleting pods of certain Status
function delete() {

if [  $all_namespaces == true  ]; then
  echo "A total of $(kubectl --context=$CONTEXT get pods -A | grep -c "$STATUS") Pod(s) with Status $STATUS will be deleted ..."

  kubectl --context=$CONTEXT get pods -A | grep "$STATUS" | awk -v context=$CONTEXT -v force="$force" '{ system ("kubectl --context=" context " delete pod " $2 " -n " $1 force ) }'

elif [ "$NAMESPACE" ] ; then
  echo "A total of $(kubectl --context=$CONTEXT get pods -n $NAMESPACE | grep -c "$STATUS") Pod(s) with Status $STATUS will be deleted ..."

  kubectl --context=$CONTEXT get pods -n $NAMESPACE | grep $STATUS | awk -v context=$CONTEXT -v force=$force '{ system ("kubectl --context=" context " delete pod " $1 force ) }'
fi

}

case "$STATUS" in
  "ContainerCreating"|"ImagePullBackOff"|"Error"|"Evicted"|"ErrImagePull") echo "Removing Pods with the given Status $STATUS"
                                                       delete
                                                       ;;

  *) echo "Given Status in not valid!"
     usage
     ;;
esac

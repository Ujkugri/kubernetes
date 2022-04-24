#! /bin/bash

function usage() {
    cat <<USAGE

    $0 - Delete Pods with specific Status in a Kubernetes Cluster

    Usage: $0 <options>

    -s | --status <Status>               : Remove Pods with this Status.
    -c | --context <Context>             : Selects Kubernetes Cluster to operate.
    -n | --namespace <Namespace>         : Namespace to operate.
    -a | --all-namespaces                : Operate over all Namespaces.
    -f | --force                         : Force deletion of Pods.
    -h | --help                          : Displays help

    Available Status are:
        ContainerCreating
        Error
        ErrImagePull
        Evicted
        ImagePullBackOff
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

# Process command line options. See usage above for supported options
function processOptions() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
           -h | --help)
              usage
              exit 0
           ;;

           -c | --context)
              CONTEXT="$2"
              if [ -z $2 ]; then

                 echo -e "\n     Error: Please provide a valid context to operate on."
                 usage
                 exit 1
              fi
              shift 2
           ;;

           -s | --status)
             STATUS="$2"
              if [ -z $2 ]; then

                 echo -e "\n     Error: Please provide a valid status."
                 usage
                 exit 1
              fi
             shift 2
           ;;

           -a | --all-namespaces)
              all_namespaces=true
              shift 1
           ;;

           -n | --namespace)
              NAMESPACE="$2"
              if [ -z $2 ]; then

                 echo -e "\n     Error: Please provide a valid namespace to operate on."
                 usage
                 exit 1
              fi
              shift 2
           ;;

           -f | --force)
              force=" --force"
              shift 1
           ;;

           \?)
              # Invalid option
              echo "Error: Invalid option"
              usage
            ;;

        esac
    done
}

# Main function for deleting pods of certain Status
function delete() {

if [  $all_namespaces == true  ]; then
  echo -e "\n     A total of $(kubectl --context=$CONTEXT get pods -A | grep -c "$STATUS") Pod(s) with Status $STATUS will be deleted ... \n"

  kubectl --context=$CONTEXT get pods -A | grep "$STATUS" | awk -v context=$CONTEXT -v force="$force" '{ system ("kubectl --context=" context " delete pod " $2 " -n " $1 force ) }'

elif [ "$NAMESPACE" ] ; then
  echo -e "\n     A total of $(kubectl --context=$CONTEXT get pods -n $NAMESPACE | grep -c "$STATUS") Pod(s) with Status $STATUS will be deleted ... \n"

  kubectl --context=$CONTEXT get pods -n $NAMESPACE | grep $STATUS | awk -v context=$CONTEXT -v force=$force '{ system ("kubectl --context=" context " delete pod " $1 force ) }'
fi

}

function status() {
case "$STATUS" in
  "ContainerCreating"|"ImagePullBackOff"|"Error"|"Evicted"|"ErrImagePull")
     echo -e "\n     Removing Pods with the given Status $STATUS"
     delete
  ;;

  *)
     echo -e "\n     Given Status in not valid!"
     usage
  ;;
esac
}

function main() {
  processOptions "$@"

  # To make sure deletion happens eiter over all namespace or one specific
  if ([ "$NAMESPACE" ] && [  $all_namespaces == true ])  || ([ -z "$NAMESPACE" ] && [  $all_namespaces == false ]) ; then
    echo -e "\n     Error: Either choose operation over all Namespaces (-a) or over a specific Namespace (-n NAMESPACE)!"
    exit 1
  fi

  status
}

######### Main #########

main "$@"

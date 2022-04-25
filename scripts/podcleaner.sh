#! /usr/bin/env bash

function usage() {
    cat <<USAGE

    $0 - Delete Pods with specific Status in a Kubernetes Cluster

    Usage: $0 <options>

    -s <Status>               : Remove Pods with this Status.
    -c <Context>              : Selects Kubernetes Cluster to operate.
    -n <Namespace>            : Namespace to operate.
    -a                        : Operate over all Namespaces.
    -f                        : Force deletion of Pods.
    -h                        : Displays help

    Available Status are:
        ContainerCreating
        Error
        ErrImagePull
        Evicted
        ImagePullBackOff
USAGE

    exit 1
}

# For errorhandling
errorExit () {
    echo -e "\n    Error: $1"
    usage
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

while getopts "han:s:fc:" option; do
   case $option in
      h)
         usage
      ;;

      c)
         CONTEXT="$OPTARG"
      ;;

      s)
         STATUS="$OPTARG"
      ;;

      a)
         all_namespaces=true
      ;;

      n)
         NAMESPACE="$OPTARG"
      ;;

      f)
         force=" --force"
      ;;

      \?)

             errorExit "Option not defined or has no argument!"
      ;;

   esac
done 2> /dev/null
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

function option_validation() {

  # To make sure deletion happen either over all namespace or one specific
  if ([ "$NAMESPACE" ] && [  $all_namespaces == true ])  || ([ -z "$NAMESPACE" ] && [  $all_namespaces == false ]) ; then
    errorExit "Either choose operation over all Namespaces (-a) or over a specific Namespace (-n NAMESPACE)!"
  fi

  # To make sure the given context is valid
  kubectl --context=$CONTEXT cluster-info > /dev/null 2>&1 || errorExit "Please provide a valid context to operate on."

}

function status() {
case "$STATUS" in
  "ContainerCreating"|"ImagePullBackOff"|"Error"|"Evicted"|"ErrImagePull")
     echo -e "\n     Removing Pods with the given Status $STATUS"
     delete
  ;;

  *)
     errorExit "Given Status in not valid!"
  ;;

  \?)
  # Invalid option
  echo "Error: Invalid option"
  usage
  ;;


esac
}

function main() {
  processOptions "$@"

#  # To make sure deletion happen either over all namespace or one specific
#  if ([ "$NAMESPACE" ] && [  $all_namespaces == true ])  || ([ -z "$NAMESPACE" ] && [  $all_namespaces == false ]) ; then
#    errorExit "Either choose operation over all Namespaces (-a) or over a specific Namespace (-n NAMESPACE)!"
#  fi

  option_validation

  status
}

######### Main #########

main "$@"

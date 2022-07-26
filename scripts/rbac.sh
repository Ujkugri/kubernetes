#! /usr/bin/env bash

set -e

function usage() {
    cat <<USAGE

    $0 - Gives Informations about (Cluster)Roles and (Cluster)RoleBindings 

    Usage: $0 <options>

    -k | --kind <Kkind>                                    Options are Roles, RoleBindings, ClusterRoles and CusterRoleBindings
    -c | --context <Context>                               Selects Kubernetes Cluster to operate.
    -n | --namespace <Namespace1,Namespace2,...>           Namespace to operate. Can be one Namespace or array of Namespaces.
    -h | --help                                            Displays help

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

NAMESPACE=""

# Process command line options. See usage above for supported options
function processOptions() {

while [ $# -gt 0 ]; do
  key="$1"

  case $key in
  -h | --help)
     usage
   ;;
    
  -c | --context)
    kubectl="kubectl --context $2"
    shift
    shift
    ;;

  -n | --namespace)
    NAMESPACE="$2" 
    shift
    shift
    ;;

  -k | --kind)
    KIND="$2"
    shift
    shift

  ;;
  --* | -*)
    shift
    usage
    break
    ;;

  \?)
    errorExit "Option not defined or has no argument!"
    usage
    ;;
  esac
done 2> /dev/null
}


function rolebindings() {
  if [ -z "$NAMESPACE" ]; then
    NAMESPACE=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    kubectl get rolebindings -n $NAMESPACE -o custom-columns='NAMESPACE:metadata.namespace,KIND:kind,ROLE:roleRef.name,ROLEKIND:roleRef.kind,NAME:metadata.name,SERVICE-ACCOUNTS:subjects[?(@.kind=="ServiceAccount")].name'
  else
    NAMESPACES=$(echo $NAMESPACE | sed "s/,/ /")
    echo -e "NAMESPACE KIND ROLE ROLEKIND NAME SERVICE-ACCOUNTS"
    for ns in $NAMESPACES
    do
      kubectl get rolebindings -n $ns -o custom-columns='NAMESPACE:metadata.namespace,KIND:kind,ROLE:roleRef.name,ROLEKIND:roleRef.kind,NAME:metadata.name,SERVICE-ACCOUNTS:subjects[?(@.kind=="ServiceAccount")].name'  --no-headers
    done
  fi
}

function roles() {
  if [ -z "$NAMESPACE" ] ; then
    NAMESPACE=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    echo -e "NAMESPACE KIND NAME RESOURCES \t VERB"
    kubectl get roles --no-headers -n $NAMESPACE | awk -v NAMESPACE=$NAMESPACE '{ system ("kubectl -n " NAMESPACE " get role " $1 " -o jsonpath='\''{range .rules[*]}{\"\\t\"}{.resources}{\"\\t\"}{.verbs}{\"\\n\"}{end}'\'' \|  sed \"s/^/ "NAMESPACE" Role " $1 "  \/\"  ")  }'
  else
    echo -e "NAMESPACE KIND NAME RESOURCES \t VERB"
    NAMESPACES=$(echo $NAMESPACE | sed "s/,/ /")
    for ns in $NAMESPACES
    do 
      kubectl get roles --no-headers -n $ns | awk -v NAMESPACE=$ns '{ system ("kubectl -n " NAMESPACE " get role " $1 " -o jsonpath='\''{range .rules[*]}{\"\\t\"}{.resources}{\"\\t\"}{.verbs}{\"\\n\"}{end}'\'' \|  sed \"s/^/ "NAMESPACE" Role " $1 "  \/\"  ")  }' 
    done
  fi
}

function clusterrolebindings() {
  echo -e "NAMESPACE KIND ROLE ROLEKIND NAME SERVICE-ACCOUNTS"
  kubectl get clusterrolebindings -o custom-columns='NAMESPACE:metadata.namespace,KIND:kind,ROLE:roleRef.name,ROLEKIND:roleRef.kind,NAME:metadata.name,SERVICE-ACCOUNTS:subjects[?(@.kind=="ServiceAccount")].name' --no-headers

}

function clusterroles() {

  echo -e "NAMESPACE KIND NAME RESOURCES \t VERB"
  kubectl get clusterroles --no-headers | awk '{ system ("kubectl get clusterrole " $1 " -o jsonpath='\''{range .rules[*]}{\"\\t\"}{.resources}{\"\\t\"}{.verbs}{\"\\n\"}{end}'\'' \|  sed \"s/^/ <None>  ClusterRole  " $1 " \/\"  ")  }' | column -t

}

function main() {

  processOptions "$@"
  case "$KIND" in
    "Roles")
      roles 
    ;;
    "ClusterRoles")
      clusterroles 
    ;;
    "RoleBindings")
       rolebindings
    ;;
    "ClusterRoleBindings")     
       clusterrolebindings
    ;;
    *)
      errorExit "Given Kind in not valid!"
    ;;
    \?)
      # Invalid option
      errorExit "Invalid Option" 
      usage
    ;;
  esac
}

######### Main #########

main "$@" | column -t

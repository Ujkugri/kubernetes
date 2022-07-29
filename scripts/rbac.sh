#! /usr/bin/env bash

set -e

function usage() {
    cat <<USAGE

    $0 - Gives Informations about (Cluster)Roles and (Cluster)RoleBindings 

    Usage: $0 <Subcommands> <Options>

    Options:
    -k | --kind <Kind>                                     Options are Roles, RoleBindings, ClusterRoles and CusterRoleBindings
    -c | --context <Context>                               Selects Kubernetes Cluster to operate.
    -n | --namespace <Namespace1,Namespace2,...>           Namespace to operate. Can be one Namespace or array of Namespaces.
    -h | --help                                            Displays help

    Subcommands:
    who-can <verb> <Resource>                              Lists all Roles or ClusterRoles that can <verb> <Resource>
                                                           Example: -k Roles who-can get Pods
                                                                    Lists all Roles who can get Pods        
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

# Process command line options. See usage above for supported options
function processOptions() {

while [ $# -gt 0 ]; do
  key="$1"

  case $key in
  -h | --help)
     usage
  ;;

  who-can) 
    if ([ -z "$2" ] || [ -z "$3" ]) ; then
      errorExit "The Option who-can needs a Resource and a Verb!" 
    fi
    RESOURCES="| grep -i $3"
    VERBS="| grep -i $2"
    shift
    shift
    shift
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
  ;;
  esac
done 2> /dev/null
}


function empty_variables() {

  if [ -z "$NAMESPACE" ]; then
    NAMESPACE=$(kubectl config view --minify --output 'jsonpath={..namespace}')
  fi

}

function rolebindings() {

  NAMESPACES=$(echo $NAMESPACE | sed "s/,/ /")
  for ns in $NAMESPACES
  do
    kubectl get rolebindings -n $ns -o custom-columns='NAMESPACE:metadata.namespace,KIND:kind,ROLE:roleRef.name,ROLEKIND:roleRef.kind,NAME:metadata.name,SERVICE-ACCOUNTS:subjects[?(@.kind=="ServiceAccount")].name'  --no-headers
  done

}

function clusterrolebindings() {

  kubectl get clusterrolebindings -o custom-columns='NAMESPACE:metadata.namespace,KIND:kind,ROLE:roleRef.name,ROLEKIND:roleRef.kind,NAME:metadata.name,SERVICE-ACCOUNTS:subjects[?(@.kind=="ServiceAccount")].name' --no-headers

}

function roles() {

  NAMESPACES=$(echo $NAMESPACE | sed "s/,/ /")
  for ns in $NAMESPACES
  do 
    kubectl get roles --no-headers -n $ns | awk -v NAMESPACE=$ns '{ system ("kubectl -n " NAMESPACE " get role " $1 " -o jsonpath='\''{range .rules[*]}{\"\\t\"}{.resources}{\"\\t\"}{.verbs}{\"\\n\"}{end}'\'' \|  sed \"s/^/ "NAMESPACE" Role " $1 "  \/\"  ")  }' 
  done


}

function clusterroles() {

  kubectl get clusterroles --no-headers | awk '{ system ("kubectl get clusterrole " $1 " -o jsonpath='\''{range .rules[*]}{\"\\t\"}{.resources}{\"\\t\"}{.verbs}{\"\\n\"}{end}'\'' \|  sed \"s/^/ <None>  ClusterRole  " $1 " \/\"  ")  }' | column -t

}

function main() {

  processOptions "$@"

  empty_variables

  case "$KIND" in
    "Roles"|"Role"|"roles"|"role")
      eval "echo -e 'NAMESPACE KIND NAME RESOURCES \t VERB';roles $RESOURCES $VERBS" 
    ;;

    "ClusterRoles"|"ClusterRole"|"clusterroles"|"clusterrole")
      eval "echo -e 'NAMESPACE KIND NAME RESOURCES \t VERB';clusterroles $RESOURCES $VERBS" 
    ;;

    "RoleBindings"|"RoleBinding"|"rolebindings"|"rolebinding")
       eval "echo -e 'NAMESPACE KIND ROLE ROLEKIND NAME SERVICE-ACCOUNTS';rolebindings" 
    ;;

    "ClusterRoleBindings"|"ClusterRoleBinding"|"clusterrolebindings"|"clusterrolebinding")
      eval "echo -e 'NAMESPACE KIND ROLE ROLEKIND NAME SERVICE-ACCOUNTS';clusterrolebindings" 
    ;;

    *)
      echo "Given Kind in not valid!"
      exit 1
    ;;

  esac | column -t

}

######### Main #########

main "$@"

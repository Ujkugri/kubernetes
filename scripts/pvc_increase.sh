#!/bin/bash

# global variables
namespace=$1
pvc_name=$2
new_size=$3

# function to check if the given storage class allows volume expansion
check_volume_expansion_support() {
    # get the storage class of the PVC
    storage_class=$(kubectl get pvc $pvc_name -n "$namespace" -o jsonpath='{.spec.storageClassName}')

    # get the allowVolumeExpansion value of the storage class
    allow_expansion=$(kubectl get storageclass $storage_class -o jsonpath='{.allowVolumeExpansion}')

    if [ "$allow_expansion" != "true" ]; then
        echo "The storage class of the PVC does not support volume expansion"
        exit 1
    fi
}

# Get the current size of the PVC and split the capacity to the integer value and the unit
function get_current_size() {
  # Get the current size of the PVC
  size=$(kubectl get pvc $pvc_name -n $namespace -o jsonpath='{.spec.resources.requests.storage}')  
}

# Compares the Units of the current size and the given size. If not equal, breaks.
function compare_units() {
  if [[ "${size: -2}" != "${new_size: -2}" ]]; then
    echo "ERROR: Unit Missmatch. The give unit of the given value and the value of the current size do not match."
    exit
  fi
}

increase_pvc_capacity() {
# Check if the current Capacity is higher than the new Capacity
if [[ ${size%??} -gt ${new_size%??} ]]; then
  echo "ERROR: The given Value for the Capacity is lower than the current Capacity."
  exit 1
fi

# Display the current size of the PVC, namespace, and PVC name
cat << USAGE
  The PVC $pvc_name in the Namespace $namespace with the current capacity of $size is now be increased to $new_size.
USAGE

kubectl patch pvc $pvc_name -p "{\"spec\":{\"resources\":{\"requests\":{\"storage\":\"${new_size}\"}}}}" -n $namespace
}

# main function
main() {
    # Check if all the required arguments are provided
    if [ -z "$namespace" ] || [ -z "$pvc_name" ] || [ -z "$new_size" ]; then
      echo "Usage: $0 <namespace> <pvc_name> <new_size>"
      echo "Example: $0 my-namespace my-pvc 5Gi"
      exit 1
    fi

    check_volume_expansion_support

    get_current_size 

    compare_units

    increase_pvc_capacity 
}

# call the main function
main

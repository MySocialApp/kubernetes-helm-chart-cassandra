#!/usr/bin/env bats

load ../k8s-euft/env
load common

@test "Ensure number of nodes is set: $NUM_NODES" {
    num_nodes_set
}

@test "Deleting Cassandra instance" {
    helm delete --purge cassandra
}

@test "Check pods are deleted" {
    current=-1
    while [ $current != 0 ] ; do
        current=$(kubectl get pod -l app=cassandra | grep "^cassandra-[0-9]" | wc -l)
        echo "Wait while deleting all pods: $current/$NUM_NODES" >&3
        sleep 5
    done
}

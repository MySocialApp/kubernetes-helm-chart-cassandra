#!/usr/bin/env bats

load ../k8s-euft/env
load common

@test "Ensure number of nodes is set: $NUM_NODES" {
    num_nodes_set
}

@test "Deleting Cassandra chart" {
    helm delete --purge cassandra
}

@test "Check pods are deleted" {
    current=-1
    while [ $current != 0 ] ; do
        current=$(kubectl get pod -l app=cassandra 2>/dev/null | grep "^cassandra-[0-9]" | wc -l)
        echo "Wait while deleting all pods: $current/$NUM_NODES, waiting..." >&3
        sleep 5
    done
}

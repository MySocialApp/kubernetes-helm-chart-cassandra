#!/usr/bin/env bash

num_nodes_set() {
    echo "Ensure number of nodes is set: $NUM_NODES"
    [ ! -z $NUM_NODES ]
}

num_nodes_are_labeled_as_node() {
    label='node-role.kubernetes.io/node=true'
    for i in $(seq 1 $NUM_NODES) ; do
        if [ $(kubectl get nodes --show-labels | grep kube-node-$i | grep $label | wc -l) == 0 ] ; then
            kubectl label nodes kube-node-$i node-role.kubernetes.io/node=true --overwrite
        fi
    done
}

num_nodes_eq_nodetool_status_un() {
    CURRENT_NODES=0
    while [ "$CURRENT_NODES" != "$NUM_NODES" ] ; do
        sleep 5
        CURRENT_NODES=$(kubectl exec -it cassandra-0 nodetool status | grep "^UN" | wc -l)
        echo "Cassandra number cluster node: $CURRENT_NODES/$NUM_NODES, waiting..." >&3
    done
}

check_cluster_is_running() {
    CURRENT_NODES=0
    READY_NODES=0

    # Ensure the number of desired pod has been bootstraped
    while [ "$CURRENT_NODES" != "$NUM_NODES" ] ; do
        sleep 15
        CURRENT_NODES=$(kubectl get pod -l app=cassandra | grep Running | wc -l)
        echo "Kubernetes running nodes: $CURRENT_NODES/$NUM_NODES, waiting..." >&3
    done

    # Ensure the state of each pod is fully ready
    while [ "$READY_NODES" != "$NUM_NODES" ] ; do
        sleep 15
        READY_NODES=$(kubectl get po | awk '{ print $2 }' | grep -v READY | awk -F'/' '{ print ($1 == $2) ? "true" : "false" }' | grep true | wc -l)
        echo "Kubernetes running ready nodes: $READY_NODES/$NUM_NODES, waiting..." >&3
    done
}
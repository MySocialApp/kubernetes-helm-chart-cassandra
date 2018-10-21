#!/usr/bin/env bats

load ../k8s-euft/env
load common

@test "Ensure number of nodes is set: $NUM_NODES" {
    num_nodes_set
}

@test "Ensure nodes has correct labels" {
    num_nodes_are_labeled_as_node
}

@test "Deploying Cassandra helm chart" {
    helm install kubernetes -n cassandra
}

@test "Check Cassandra cluster is deployed" {
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

@test "Check all Cassandra nodes are Up and Normal" {
    num_nodes_eq_nodetool_status_un
}

@test "Upgrade test" {
    # Test upgrade of the current helm with same content to ensure there is no mistakes
    helm upgrade cassandra kubernetes
}
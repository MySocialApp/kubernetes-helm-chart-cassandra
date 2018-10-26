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
    check_cluster_is_running
}

@test "Check all Cassandra nodes are Up and Normal" {
    num_nodes_eq_nodetool_status_un
}

@test "Re-run deploy on the current version" {
    # Test upgrade of the current helm with same content to ensure there is no mistakes
    helm upgrade cassandra kubernetes
}
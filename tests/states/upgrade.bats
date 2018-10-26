#!/usr/bin/env bats

load ../k8s-euft/env
load common

@test "Deploying Cassandra helm chart" {
    helm upgrade cassandra kubernetes
}

@test "Check Cassandra cluster is deployed" {
    check_cluster_is_running
}

@test "Check all Cassandra nodes are Up and Normal" {
    num_nodes_eq_nodetool_status_un
}
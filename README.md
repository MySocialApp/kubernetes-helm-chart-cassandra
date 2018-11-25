# kubernetes-helm-chart-cassandra

You can find here a helm chart we're using at [MySocialApp](https://mysocialapp.io)

This is a Kubernetes Helm Chart for Cassandra with several useful monitoring and management tools.

## Backups

You can automatically backup on AWS S3. A cronjob exist for it, you simple have to set the "cassandraBackup" parameters.

* To list backups for a statefulset instance, connect to an instance like in this example and call the script:

```bash
kubectl exec -it cassandra-0 bash
/usr/local/apache-cassandra/scripts/snapshot2s3.sh list <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY> <AWS_PASSPHRASE> <AWS_BUCKET>
```

Replace all AWS information with the corresponding ones.

* To restore backups, configure properly the "restoreFolder" var and run this command:

```bash
kubectl exec -it cassandra-0 bash
/usr/local/apache-cassandra/scripts/snapshot2s3.sh restore <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY> <AWS_PASSPHRASE> <AWS_BUCKET> <RESTORE_TIME>
```

RESTORE_TIME should be used as described in the [Duplicity manual Time Format section](http://duplicity.nongnu.org/duplicity.1.html#sect8).
For example (3D to restore the the last 3 days backup)

You can then use the script cassandra-restore.sh to restore a desired keyspace with all or one table:

```bash
/usr/local/apache-cassandra/scripts/cassandra-restore.sh /var/lib/cassandra/restore/var/lib/cassandra/data [keyspace]
```

Try to use help if you need more info about it.

## Managed Cassandra repairs

You can enable [Cassandra Reaper](http://cassandra-reaper.io) within your cluster to get self managed Cassandra repairs.

[A graphical interface is available](http://cassandra-reaper.svc) with an API. You have to enable a reaper server and server registration from the config:

```yaml
# Cassandra Reaper Client register
cassandraReaperRegister:
  enableReaperRegister: true
  reaperServerServiceName: cassandra-reaper.svc

# Cassandra Reaper Server
cassandraReaper:
  enableReaper: true
```

Then configure the other settings to make it work as you want.

Note: The backend is forced to Cassandra to get Reaper persistence, distribution and high availability.

## Prometheus exporter

You can setup [Cassandra exporter](https://github.com/criteo/cassandra_exporter) to grab info from each cluster nodes and export them in Prometheus format simply
by updating those lines:

```yaml
# Cassandra Exporter
cassandraExporter:
  enableExporter: true
```

Update as well other settings if you need.

Important: scraping outside the statefulset can multiply x10 the scraping time. That's why exporters are as close as possible from Cassandra nodes. That also mean that
you have to side the limits properly to avoid Kubernetes CrashloopBackoff because of Java OOM. It is strongly advised to monitor memory usage of the exporter.

## Prometheus

If you're using [Prometheus Operator](https://github.com/coreos/prometheus-operator), you can automatically scrap metrics from [Cassandra exporter](https://github.com/criteo/cassandra_exporter) this way:

```yaml
# Prometheus scraping
cassandraPrometheusScrap:
  enableScrap: true
```

## Alertmanager

If you're using [Prometheus Operator](https://github.com/coreos/prometheus-operator), you can automatically have some default alerts through Alertmanager. You simply have to enable them this way:

```yaml
# Alertmanager
cassandraAlertmanager:
  enableAlerts: true
```

And adapt alert labels to you configuration.

## Casspoke

[Casspoke](https://github.com/criteo/casspoke) is a latency probe checker for Cassandra. To enable it:

```yaml
# Casspoke
casspoke:
  enablePoke: true
```

Update as well other settings if you need.

# FAQ
## How to replace a Node?

With the statefulset, it can be hard to send spectific parameters to a node. That's why there is an override script
on boot to help on adding configuration parameters or specificities.

Let's say you've a 6 nodes cluster and want to replace 2nd node (cassandra-1) because of corrupted data. First, look
at the current status:
```
root@cassandra-0:/# /usr/local/apache-cassandra/bin/nodetool status
Datacenter: dc1
====================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address         Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.233.95.137   16.28 MiB  256          49.7%             eea07a91-5e4b-4864-83fe-0b308b7852ef  Rack1
UN  10.233.82.219   15.63 MiB  256          50.5%             39fb9d94-3d38-423e-af52-8d41f1a1591d  Rack1
DN  10.233.93.174   41.38 MiB  256          51.1%             8aa01735-1970-4c30-b107-5acf28a614a1  Rack1
UN  10.233.95.211   16.61 MiB  256          48.6%             fc7065de-e4db-45f3-ac5b-86956e35df4f  Rack1
UN  10.233.121.130  17.2 MiB   256          51.5%             8c817b60-3be5-4b59-99cc-91d1d116d711  Rack1
UN  10.233.68.55    16.39 MiB  256          48.5%             e319c1c2-0b00-4377-b6f9-64dac1553d42  Rack1
```

To replace the dead node, edit configmap directly and add this line before run.sh:
```
run_override.sh: |-
  #!/bin/bash
  source /usr/local/apache-cassandra/scripts/envVars.sh
  /usr/local/apache-cassandra/scripts/jvm_options.sh

  # Replace 10.233.93.174 with the ip of the node down
  test "$(hostname)" == 'cassandra-1' && export CASSANDRA_REPLACE_NODE=10.233.93.174

  /run.sh
```

Replace cassandra-1 and the IP address with yours. Then delete the content of the Cassandra data folder (with commit logs etc...) and delete the pod (here cassandra-1).
It will then replace the dead one by resyncing the content and it could takes time depending on the data size. **Do not forget to remove the line previously inserted when finished**.

# kubernetes-helm-chart-cassandra

You can find here a helm chart we're using at [MySocialApp](https://mysocialapp.io) (iOS and Android social app builder - SaaS)

Kubernetes Helm Chart for Cassandra

# Backups

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
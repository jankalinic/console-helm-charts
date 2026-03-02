# StreamsHub Console Operator — Helm Chart

A Helm chart for the [StreamsHub Console Operator](https://github.com/streamshub/console), which deploys and manages the StreamsHub Console — a web-based UI for monitoring Apache Kafka® clusters running on Kubernetes.

> **Note:** This chart is a community-maintained Helm packaging of the StreamsHub Console Operator.
> A proposal to include it in the upstream project is in progress.
> The canonical installation method remains the [OLM-based operator bundle](https://github.com/streamshub/console).

---

## Overview

The StreamsHub Console provides:

- Topic and consumer group browsing with message search and filtering
- Broker disk usage monitoring
- Integration with Strimzi-managed Kafka clusters
- Prometheus metrics support
- Schema Registry integration (Apicurio)
- Kafka Connect cluster visibility

The operator manages the lifecycle of Console instances via a `Console` Custom Resource. Once the operator is installed, you deploy one `Console` CR per Kafka environment you want to monitor.

---

## Prerequisites

- Kubernetes **1.25+**
- Helm **3.7+**
- [Strimzi Cluster Operator](https://strimzi.io) installed with at least one `Kafka` CR deployed
- (Optional) Prometheus Operator for metrics integration
- (Optional) Apicurio Registry for schema registry integration

---

## Installation

### Add the chart repository

```bash
helm install streamshub-console-operator \
  oci://quay.io/rhn_support_jkalinic/console-helm-charts/streamshub-console-operator \
  --version 0.11.0 \
  --namespace streamshub-console \
  --create-namespace
```

### Verify the operator is running

```bash
kubectl get pods -n streamshub-console -l app.kubernetes.io/name=streamshub-console-operator
```

---

## Usage

Once the operator is running, create a `Console` CR to deploy a console instance.

### Minimal example

```yaml
apiVersion: console.streamshub.github.com/v1alpha1
kind: Console
metadata:
  name: my-console
spec:
  hostname: console.my-cluster.example.com
  kafkaClusters:
    - name: my-kafka          # Name of the Strimzi Kafka CR
      namespace: kafka         # Namespace where the Kafka CR lives
      listener: secure         # Listener name defined on the Kafka CR
      credentials:
        kafkaUser:
          name: my-kafka-user  # Name of the KafkaUser CR
```

### Full example with Prometheus metrics

```yaml
apiVersion: console.streamshub.github.com/v1alpha1
kind: Console
metadata:
  name: example
spec:
  hostname: example-console.${CLUSTER_DOMAIN}
  metricsSources:
    # Array of connected Prometheus servers
    # - name: my-prometheus
    #   type: openshift-monitoring   # or: standalone
    #   url: https://prometheus.example.com
  schemaRegistries:
    # Array of Apicurio Registry instances
    # - name: my-registry
    #   url: https://registry.example.com
  kafkaClusters:
    - name: console-kafka
      namespace: ${KAFKA_NAMESPACE}
      listener: secure
      metricsSource: null       # Name from metricsSources above
      schemaRegistry: null      # Name from schemaRegistries above
      properties:
        values: []              # Direct connection properties (name/value pairs)
        valuesFrom: []          # References to ConfigMaps or Secrets
      credentials:
        kafkaUser:
          name: console-kafka-user1
  kafkaConnectClusters:
    # Array of Kafka Connect clusters
    # - name: my-connect-cluster
    #   url: http://my-connect-cluster.example.com/
    #   kafkaClusters:
    #     - ${KAFKA_NAMESPACE}/console-kafka
```

### Example Kafka cluster (Strimzi + Kafka(KRaft))

If you need a Kafka cluster to test with, the upstream repository includes a minimal Strimzi setup using KRaft mode and KafkaNodePools. You can apply the examples directly from GitHub without cloning:

```bash
BASE=https://raw.githubusercontent.com/streamshub/console/main/examples/kafka

# 1. Metrics ConfigMap
kubectl apply -f ${BASE}/010-ConfigMap-console-kafka-metrics.yaml

# 2. KafkaNodePools (brokers + controllers)
kubectl apply -f ${BASE}/020-KafkaNodePool-broker-console-nodepool.yaml
kubectl apply -f ${BASE}/021-KafkaNodePool-controller-console-nodepool.yaml

# 3. Kafka cluster
kubectl apply -f ${BASE}/030-Kafka-console-kafka.yaml

# 4. KafkaUser and KafkaTopic
kubectl apply -f ${BASE}/040-KafkaUser-console-kafka-user1.yaml
kubectl apply -f ${BASE}/050-KafkaTopic-console-topic.yaml
```
The full examples directory is available at github.com/streamshub/console/tree/main/examples/kafka.

The example Kafka cluster is configured with:
- 3 brokers + 3 controllers (KRaft mode, no ZooKeeper)
- SCRAM-SHA-512 authentication on a TLS listener
- JMX Prometheus Exporter metrics enabled
- CruiseControl for rebalancing

---

## Configuration

The following values can be overridden in `values.yaml` or via `--set`:

| Parameter | Description | Default |
|---|---|---|
| `image.repository` | Operator image repository | `quay.io/streamshub/console-operator` |
| `image.tag` | Operator image tag | Chart `appVersion` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `replicaCount` | Number of operator replicas | `1` |
| `serviceMonitor.enabled` | Deploy a Prometheus `ServiceMonitor` | `true` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `500m` |
| `resources.requests.memory` | Memory request | `512Mi` |
| `imagePullSecrets` | Image pull secrets for private registries | `[]` |
| `extraEnv` | Extra environment variables for the operator container | `[]` |

### Example: scoped namespace watch

By default the operator is designed to watch all namespaces for `Console` CRs.

---

## OpenShift notes

The operator is supported on k8s clusters. The chart includes a `ClusterRoleBinding` for `cluster-monitoring-view`, which exists by default on OpenShift and grants access to the built-in Thanos/Prometheus stack. On vanilla Kubernetes this role does not exist — if you are not on OpenShift and see an error about this binding, you can safely ignore it or create an empty `cluster-monitoring-view` ClusterRole manually.

The preferred installation method on OpenShift is via [OperatorHub](https://operatorhub.io) using the OLM bundle, which handles OpenShift-specific configuration automatically.

---

## Uninstallation

```bash
helm uninstall streamshub-console-operator -n streamshub-console
```

> **Note:** The `Console` CRD is annotated with `helm.sh/resource-policy: keep` by default, meaning it will **not** be deleted on uninstall to protect any existing `Console` instances. To fully remove the CRD:
> ```bash
> kubectl delete crd consoles.console.streamshub.github.com
> ```

---

## Contributing

This Helm chart is a community contribution. To propose including it in the upstream StreamsHub project, see the official project [streamshub/console](https://github.com/streamshub/console/).

For issues with the operator, please open an issue at [streamshub/console](https://github.com/streamshub/console/issues).

---

## License

Apache License 2.0 — see [LICENSE](https://github.com/streamshub/console/blob/main/LICENSE) for details.
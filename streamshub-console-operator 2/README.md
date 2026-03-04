# StreamsHub Console Operator — Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/streamshub)](https://artifacthub.io/packages/helm/streamshub-console-operator-community-jkalinic/streamshub-console-operator)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://github.com/streamshub/console/blob/main/LICENSE)
[![Operator Version](https://img.shields.io/badge/operator-0.11.0-green.svg)](https://github.com/streamshub/console/releases/tag/0.11.0)

A Helm chart for the [StreamsHub Console Operator](https://github.com/streamshub/console), which deploys and manages the StreamsHub Console — a web-based UI for monitoring Apache Kafka® clusters running on Kubernetes.

> **Note:** This chart is a community-maintained Helm packaging of the StreamsHub Console Operator.
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

The operator manages the lifecycle of Console instances via a `Console` Custom Resource. Once the operator is installed, deploy one `Console` CR per Kafka environment you want to monitor.

---

## Prerequisites

| Requirement | Version |
|---|---|
| Kubernetes | `1.25+` |
| Helm | `3.7+` |
| [Strimzi Cluster Operator](https://strimzi.io) | Any supported version with at least one `Kafka` CR |
| Prometheus Operator | Optional — required for metrics integration |
| Apicurio Registry | Optional — required for schema registry integration |

---

## Installation

### Install the operator

```bash
helm install streamshub-console-operator \
  oci://docker.io/jkalinic/streamshub-console-operator \
  --version 0.11.0 \
  --namespace streamshub-console \
  --create-namespace
```

### Install with OpenShift support enabled

```bash
helm install streamshub-console-operator \
  oci://docker.io/jkalinic/streamshub-console-operator \
  --version 0.11.0 \
  --namespace streamshub-console \
  --create-namespace \
  --set openshift.enabled=true
```

### Verify the operator is running

```bash
kubectl get pods -n streamshub-console \
  -l app.kubernetes.io/name=streamshub-console-operator
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
      namespace: kafka        # Namespace where the Kafka CR lives
      listener: secure        # Listener name defined on the Kafka CR
      credentials:
        kafkaUser:
          name: my-kafka-user # Name of the KafkaUser CR
```

### Full example with Prometheus metrics

```yaml
apiVersion: console.streamshub.github.com/v1alpha1
kind: Console
metadata:
  name: my-console
spec:
  hostname: console.example.com
  metricsSources:
    - name: my-prometheus
      type: standalone          # or: openshift-monitoring, embedded
      url: https://prometheus.example.com
  schemaRegistries:
    - name: my-registry
      url: https://registry.example.com
  kafkaClusters:
    - name: my-kafka
      namespace: kafka
      listener: secure
      metricsSource: my-prometheus
      schemaRegistry: my-registry
      credentials:
        kafkaUser:
          name: my-kafka-user
  kafkaConnectClusters:
    - name: my-connect-cluster
      url: http://my-connect-cluster.kafka.svc:8083
      kafkaClusters:
        - my-kafka
```

### Example Kafka cluster (Strimzi + KRaft)

If you need a Kafka cluster to test with, the upstream repository includes a minimal Strimzi setup using KRaft mode. You can apply the examples directly from GitHub:

```bash
BASE=https://raw.githubusercontent.com/streamshub/console/main/examples/kafka

kubectl apply -f ${BASE}/010-ConfigMap-console-kafka-metrics.yaml
kubectl apply -f ${BASE}/020-KafkaNodePool-broker-console-nodepool.yaml
kubectl apply -f ${BASE}/021-KafkaNodePool-controller-console-nodepool.yaml
kubectl apply -f ${BASE}/030-Kafka-console-kafka.yaml
kubectl apply -f ${BASE}/040-KafkaUser-console-kafka-user1.yaml
kubectl apply -f ${BASE}/050-KafkaTopic-console-topic.yaml
```

The full examples directory is available at [github.com/streamshub/console/tree/main/examples/kafka](https://github.com/streamshub/console/tree/main/examples/kafka).

The example Kafka cluster is configured with:
- 3 brokers + 3 controllers (KRaft mode, no ZooKeeper)
- SCRAM-SHA-512 authentication on a TLS listener
- JMX Prometheus Exporter metrics enabled
- CruiseControl for rebalancing

---

## Configuration

All parameters can be overridden in a `values.yaml` file or via `--set`.

| Parameter | Description | Default |
|---|---|---|
| `replicaCount` | Number of operator replicas. Must be `1`. | `1` |
| `image.repository` | Operator image repository | `quay.io/streamshub/console-operator` |
| `image.tag` | Operator image tag. Defaults to chart `appVersion`. | `""` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `imagePullSecrets` | Pull secrets for private registries | `[]` |
| `nameOverride` | Override the chart name used in resource naming | `""` |
| `fullnameOverride` | Override the fully qualified resource name | `""` |
| `serviceAccount.create` | Create the ServiceAccount | `true` |
| `serviceAccount.name` | Custom ServiceAccount name. Defaults to fullname. | `""` |
| `rbac.create` | Create RBAC resources (ClusterRoles, bindings) | `true` |
| `openshift.enabled` | Enable OpenShift-specific resources (`cluster-monitoring-view` binding) | `false` |
| `deployConsoleInstance` | Deploy a `Console` CR alongside the operator | `false` |
| `consoleInstance.hostname` | Hostname for the Console UI. Required when `deployConsoleInstance=true`. | `""` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.requests.memory` | Memory request |
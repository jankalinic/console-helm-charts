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

### Operator only
```bash
helm install console \
  oci://docker.io/jkalinic/streamshub-console-operator \
  --version 0.11.1-snapshot \
  --namespace co-namespace \
  --create-namespace
```

### With OpenShift support
```bash
helm install console \
  oci://docker.io/jkalinic/streamshub-console-operator \
  --version 0.11.1-snapshot \
  --namespace co-namespace \
  --create-namespace \
  --set openshift.enabled=true
```

### With Strimzi as a subchart

If you don't have Strimzi installed yet, this chart can install it as a dependency:
```bash
helm install console \
  oci://docker.io/jkalinic/streamshub-console-operator \
  --version 0.11.1-snapshot \
  --namespace co-namespace \
  --create-namespace \
  --set strimzi.enabled=true \
  --set strimzi.strimzi-kafka-operator.watchNamespaces="{co-namespace}"
```

### With an example Kafka cluster and Console instance

Deploys the operator, a Strimzi-managed Kafka cluster, and a Console instance in one command:
```bash
helm install console \
  oci://docker.io/jkalinic/streamshub-console-operator \
  --version 0.11.1-snapshot \
  --namespace co-namespace \
  --create-namespace \
  --set strimzi.enabled=true \
  --set strimzi.strimzi-kafka-operator.watchNamespaces="{co-namespace}" \
  --set exampleKafka.enabled=true \
  --set deployConsoleInstance=true \
  --set clusterDomain=192.168.49.2.nip.io
```

### Verify the operator is running
```bash
kubectl get pods -n co-namespace \
  -l app.kubernetes.io/name=console
```

---

## Resource naming

All resources are named after the Helm release name to keep names short and predictable.
Using `helm install console ...` produces:

| Resource | Name |
|---|---|
| Operator Deployment | `console-console` |
| Kafka CR | `console-kafka` |
| Console CR | `console` |
| KafkaUser | `console-kafka-user` |
| KafkaTopic | `console-topic` |

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
    - name: my-kafka
      namespace: kafka
      listener: secure
      credentials:
        kafkaUser:
          name: my-kafka-user
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
      type: standalone
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

---

## Uninstallation

### Basic uninstall
```bash
helm uninstall console -n co-namespace
```

> **Note:** This leaves behind any `Console`, `Kafka`, `KafkaUser`, and `KafkaTopic` CRs.
> You will need to remove them manually.

### Full cleanup — remove all CRs on uninstall

To have the pre-delete hook automatically remove all CRs and wait for operator
cleanup before uninstalling, enable `fullCleanup` via an upgrade first:
```bash
helm upgrade console \
  oci://docker.io/jkalinic/streamshub-console-operator \
  --reuse-values \
  --set fullCleanup=true \
  -n co-namespace

helm uninstall console -n co-namespace
```

This will, in order:

1. Strip all finalizers from Console, Kafka, KafkaUser, KafkaTopic, and KafkaNodePool CRs
2. Delete all CRs and wait for them to be fully removed
3. Remove the operator and all chart resources

### Full cleanup including CRDs

To also remove CRDs on uninstall (use with caution — this affects all clusters using these CRDs):
```bash
helm upgrade console \
  oci://docker.io/jkalinic/streamshub-console-operator \
  --reuse-values \
  --set fullCleanup=true \
  --set deleteCRDs=true \
  -n co-namespace

helm uninstall console -n co-namespace
```

> Strimzi CRDs are only deleted if Strimzi was installed as a subchart (`strimzi.enabled=true`).
> If you brought your own Strimzi installation, its CRDs are left untouched.

---

## Configuration

For the full list of configurable parameters and their defaults, see
[values.yaml](https://github.com/jankalinic/console-helm-charts/blob/main/streamshub-console-operator/values.yaml).

---

## Example Kafka cluster

If you need a Kafka cluster to test with and want to deployit yourself, the upstream repository includes a minimal
Strimzi setup using KRaft mode. You can apply the examples directly from GitHub:
```bash
BASE=https://raw.githubusercontent.com/streamshub/console/main/examples/kafka

kubectl apply -f ${BASE}/010-ConfigMap-console-kafka-metrics.yaml
kubectl apply -f ${BASE}/020-KafkaNodePool-broker-console-nodepool.yaml
kubectl apply -f ${BASE}/021-KafkaNodePool-controller-console-nodepool.yaml
kubectl apply -f ${BASE}/030-Kafka-console-kafka.yaml
kubectl apply -f ${BASE}/040-KafkaUser-console-kafka-user1.yaml
kubectl apply -f ${BASE}/050-KafkaTopic-console-topic.yaml
```

The full examples directory is available at
[github.com/streamshub/console/tree/main/examples/kafka](https://github.com/streamshub/console/tree/main/examples/kafka).
---
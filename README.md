# StreamsHub Community Helm Charts

Community-maintained Helm charts for [StreamsHub](https://github.com/streamshub) projects.

> These charts are not officially maintained by the StreamsHub project.
> For the official installation method, see the [StreamsHub Console Operator](https://github.com/streamshub/console).

## Charts

| Chart                                                               | Description | Version |
|---------------------------------------------------------------------|---|---|
| [streamshub-console-operator](streamshub-console-operator) | Deploys the StreamsHub Console Operator for monitoring Apache Kafka® clusters | 0.11.0 |

## Usage

Charts are distributed via OCI on Quay:

```bash
helm install streamshub-console-operator \
  oci://quay.io/docker.io/jkalinic/streamshub-console-operator \
  --version 0.11.0 \
  --namespace streamshub-console \
  --create-namespace
```

Full documentation for each chart is available on [Artifact Hub](https://artifacthub.io).

## Contributing

Issues and PRs are welcome. For bugs or feature requests related to the operator itself please use the [upstream repository](https://github.com/streamshub/console/issues).

## License

Apache License 2.0
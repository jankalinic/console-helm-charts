{{/*
Expand the name of the chart.
*/}}
{{- define "streamshub-console-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
Truncated to 63 characters as required by Kubernetes DNS naming rules.
*/}}
{{- define "streamshub-console-operator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Cluster-scoped resource name — includes namespace to avoid collisions when
the chart is installed in multiple namespaces on the same cluster.
ClusterRoles and ClusterRoleBindings are cluster-wide so two releases in
different namespaces would otherwise conflict on the same name.
*/}}
{{- define "streamshub-console-operator.clusterResourceName" -}}
{{- printf "%s-%s" (include "streamshub-console-operator.fullname" .) .Release.Namespace | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Operator image with tag. Tag defaults to chart appVersion.
*/}}
{{- define "streamshub-console-operator.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{/*
ServiceAccount name.
- If serviceAccount.create is false, a name must be provided explicitly.
- If serviceAccount.create is true, uses the provided name or falls back to fullname.
*/}}
{{- define "streamshub-console-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- .Values.serviceAccount.name | default (include "streamshub-console-operator.fullname" .) }}
{{- else }}
{{- required "serviceAccount.name is required when serviceAccount.create is false" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Console instance hostname.
Built from fullname + clusterDomain when clusterDomain is set.
Falls back to consoleInstance.hostname if clusterDomain is not set.
Example with clusterDomain: streamshub-console-operator.192.168.49.2.nip.io
Example with hostname:       console.example.com
*/}}
{{- define "streamshub-console-operator.consoleHostname" -}}
{{- if .Values.clusterDomain }}
{{- printf "%s.%s" (include "streamshub-console-operator.fullname" .) .Values.clusterDomain }}
{{- else }}
{{- .Values.consoleInstance.hostname }}
{{- end }}
{{- end }}

{{/*
Common labels — applied to all resources.
*/}}
{{- define "streamshub-console-operator.labels" -}}
app.kubernetes.io/name: {{ include "streamshub-console-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end }}

{{/*
Selector labels — used in Deployment.spec.selector and Service.spec.selector.
Must remain stable across upgrades (never add/remove fields once deployed).
*/}}
{{- define "streamshub-console-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "streamshub-console-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
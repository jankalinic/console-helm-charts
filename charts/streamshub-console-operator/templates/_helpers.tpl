{{/*
Expand the name of the chart.
*/}}
{{- define "streamshub-console-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Operator image with tag
*/}}
{{- define "streamshub-console-operator.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{/*
ServiceAccount name
*/}}
{{- define "streamshub-console-operator.serviceAccountName" -}}
{{- .Values.serviceAccount.name | default "streamshub-console-operator" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "streamshub-console-operator.labels" -}}
app.kubernetes.io/name: streamshub-console-operator
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "streamshub-console-operator.selectorLabels" -}}
app.kubernetes.io/name: streamshub-console-operator
{{- end }}

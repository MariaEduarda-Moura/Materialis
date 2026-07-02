{{- define "materialis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "materialis.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "materialis.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "materialis.labels" -}}
app.kubernetes.io/name: {{ include "materialis.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "materialis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "materialis.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "materialis.appName" -}}
materialis-app
{{- end -}}

{{- define "materialis.mysqlName" -}}
materialis-mysql
{{- end -}}

{{- define "materialis.mailpitName" -}}
materialis-mailpit
{{- end -}}

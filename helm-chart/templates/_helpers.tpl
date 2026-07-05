{{/*
Expand the name of the chart.
*/}}
{{- define "voting-app.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "voting-app.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Chart label: name + version
*/}}
{{- define "voting-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource
*/}}
{{- define "voting-app.labels" -}}
helm.sh/chart: {{ include "voting-app.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{/*
Selector labels for a given component  — call as:
  include "voting-app.selectorLabels" (dict "component" "vote")
*/}}
{{- define "voting-app.selectorLabels" -}}
app: {{ .component }}
{{- end }}

{{/*
Full image reference:  registry/repository:tag
  Usage: include "voting-app.image" (dict "registry" .Values.registry "image" .Values.vote.image)
  For public images (db / redis) pass empty registry.
*/}}
{{- define "voting-app.image" -}}
{{- if .registry -}}
{{ .registry }}/{{ .image.repository }}:{{ .image.tag }}
{{- else -}}
{{ .image.repository }}:{{ .image.tag }}
{{- end -}}
{{- end }}

{{/*
ConfigMap name — centralised so it matches the configMap.name value
*/}}
{{- define "voting-app.configMapName" -}}
{{ .Values.configMap.name }}
{{- end }}

{{/*
Secret name
*/}}
{{- define "voting-app.secretName" -}}
{{ .Values.secret.name }}
{{- end }}

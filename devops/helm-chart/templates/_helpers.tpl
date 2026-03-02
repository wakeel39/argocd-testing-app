{{/*
Expand the name of the chart.
*/}}
{{- define "argocdnodejsapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "argocdnodejsapp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- default "node-app" $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "argocdnodejsapp.labels" -}}
app: {{ include "argocdnodejsapp.fullname" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "argocdnodejsapp.selectorLabels" -}}
app: {{ include "argocdnodejsapp.fullname" . }}
{{- end }}

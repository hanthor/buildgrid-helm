{{/*
Expand the name of the chart.
*/}}
{{- define "buildgrid.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "buildgrid.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "buildgrid.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "buildgrid.labels" -}}
helm.sh/chart: {{ include "buildgrid.chart" . }}
{{ include "buildgrid.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "buildgrid.selectorLabels" -}}
app.kubernetes.io/name: {{ include "buildgrid.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "buildgrid.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "buildgrid.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL hostname
*/}}
{{- define "buildgrid.postgresql.host" -}}
{{- if .Values.postgresql.enabled }}
{{ include "buildgrid.fullname" . }}-postgresql
{{- else }}
{{ .Values.postgresql.externalHost }}
{{- end }}
{{- end }}

{{/*
PostgreSQL port
*/}}
{{- define "buildgrid.postgresql.port" -}}
{{- if .Values.postgresql.enabled -}}
5432
{{- else -}}
{{ .Values.postgresql.externalPort | default 5432 }}
{{- end -}}
{{- end }}

{{/*
Redis hostname
*/}}
{{- define "buildgrid.redis.host" -}}
{{- if .Values.redis.enabled }}
{{ include "buildgrid.fullname" . }}-redis
{{- else }}
{{ .Values.redis.externalHost }}
{{- end }}
{{- end }}

{{/*
Redis port
*/}}
{{- define "buildgrid.redis.port" -}}
{{- if .Values.redis.enabled }}
6379
{{- else }}
{{ .Values.redis.externalPort | default 6379 }}
{{- end }}
{{- end }}

{{/*
Database URL
*/}}
{{- define "buildgrid.database.url" -}}
postgresql://{{ .Values.postgresql.auth.username }}:{{ .Values.postgresql.auth.password | urlquery }}@{{ include "buildgrid.postgresql.host" . }}:{{ include "buildgrid.postgresql.port" . }}/{{ .Values.postgresql.auth.database }}
{{- end }}

{{/*
Redis URL
*/}}
{{- define "buildgrid.redis.url" -}}
{{- if .Values.redis.auth.enabled }}
redis://:{{ .Values.redis.auth.password | urlquery }}@{{ include "buildgrid.redis.host" . }}:{{ include "buildgrid.redis.port" . }}/0
{{- else }}
redis://{{ include "buildgrid.redis.host" . }}:{{ include "buildgrid.redis.port" . }}/0
{{- end }}
{{- end }}

{{/*
Storage path
*/}}
{{- define "buildgrid.storage.path" -}}
{{ .Values.buildgrid.storage.backend.filesystem.path }}
{{- end }}

{{/*
Common pod metadata
*/}}
{{- define "buildgrid.podAnnotations" -}}
prometheus.io/scrape: "true"
prometheus.io/port: "8080"
prometheus.io/path: "/metrics"
{{- end }}

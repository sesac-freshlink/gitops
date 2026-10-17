{{- define "spring-service.name" -}}
{{- .Release.Name -}}
{{- end -}}

{{- define "spring-service.labels" -}}
app.kubernetes.io/name: {{ include "spring-service.name" . }}
app.kubernetes.io/part-of: freshlink
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "spring-service.selector" -}}
app.kubernetes.io/name: {{ include "spring-service.name" . }}
{{- end -}}

{{- define "spring-service.image" -}}
{{- $registry := required "cluster.imageRegistry가 필요하다 (ArgoCD가 넣는다)" .Values.cluster.imageRegistry -}}
{{- $tag := required "image.tag가 필요하다 (CI가 커밋한다)" .Values.image.tag -}}
{{- if eq $tag "latest" }}{{ fail "image.tag에 latest를 쓰지 않는다" }}{{ end -}}
{{- printf "%s/%s:%s" $registry (default .Release.Name .Values.image.name) $tag -}}
{{- end -}}

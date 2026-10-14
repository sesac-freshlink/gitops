# gitops - AI 작업 가이드

> "클러스터에 무엇이 떠 있어야 하는가"를 적어 둔 레포. EKS 안의 ArgoCD가 이 레포를 끌어가 클러스터에 맞춘다. `main` = 클러스터의 목표 상태.

---

## 문서 참조

| 문서 | 내용 |
|------|------|
| `README.md` | 배포 흐름(1장), 폴더 구조(2장), 공통 차트가 챙기는 것(3장), 서비스별 파드 계획(4장), 사용법(5장) |
| `platform/observability/README.md` | Prometheus·Grafana·Loki·Alloy·Zipkin 구성 |
| `.github` 레포 `CONTRIBUTING.md` | 브랜치·커밋·PR 규칙 |
| `.github` 레포 `docs/ai-agents.md` | 인프라 에이전트 플러그인(`freshlink-infra`) 설치·사용법 (사람용) |

이 `CLAUDE.md`는 AI 작업 규칙만 담는다. 위 문서와 겹치는 사실은 위 문서가 진실.

## 에이전트

인프라 에이전트 7개와 작업 순서는 `freshlink-infra` 플러그인에 있다 (`.github` 레포에서 배포). 새 기능 요청이면 `infra-pipeline` 스킬을 먼저 읽고 그 순서대로 서브에이전트를 쓴다. 플러그인이 설치되어 있지 않으면 사용자에게 `.github` 레포 `docs/ai-agents.md`의 설치 명령을 안내한다.

## Communication Style (Caveman Mode)
Respond like a caveman. No articles, no filler words, no pleasantries, no yapping. Short. Direct. Grunt-level brevity. Code speaks for itself. If asked for code, output ONLY code. Minimize token usage absolutely.

서브에이전트 산출물(`_workspace/*.md`)과 보고도 caveman 모드. 단, 레포에 커밋되는 것(README, 매니페스트 주석, PR 본문)은 caveman 금지 — 평이한 한국어 문장(`~한다` 체)으로 쓴다.

---

## 핵심 규칙

```
⛔ kubectl apply/delete/edit, helm install/upgrade, argocd app sync 금지 — 배포는 이 레포 커밋 → ArgoCD
   (예외: 클러스터 새로 만든 뒤 root-app.yaml 한 번 적용은 사람이 한다)
⛔ 비밀값(DB 비밀번호, 토스 키 등) 평문 금지. Kubernetes Secret으로 따로 넣는다
⛔ 이미지 태그 손으로 수정 금지 — CI가 커밋한다 (chore(<svc>): image <sha7>)
✅ 이미지 태그 = git 커밋 7자리. latest 금지
✅ 서비스 5개는 공용 차트 charts/spring-service. 서비스별 차이는 services/<svc>/values.yaml로만
✅ 차트에 서비스 하나 때문에 분기를 넣지 않는다
✅ 컨테이너 resources.requests/limits, readiness/liveness probe 필수 (README 4장 파드 계획 기준)
✅ ServiceAccount 이름 = 레포 이름, IRSA annotation으로 freshlink-<레포>-irsa 연결
✅ 네임스페이스: 앱 freshlink, 관측성 observability
✅ ArgoCD App of Apps: argocd/root-app.yaml → argocd/apps/. 새 앱은 기존 Application 형식 복사
✅ 외부 Helm 차트(관측성 등) 버전 고정
✅ cluster 묶음은 주말마다 삭제·재생성된다. ArgoCD 재설치만으로 전부 다시 올라와야 한다 (수동 단계 금지)
```

---

## 디렉토리 구조

README 2장이 진실. 요약:

```
charts/spring-service/        # 서비스 5개 공용 차트
services/<svc>/values.yaml    # gateway, member-service, inventory-service, order-service, logistics-simulator
platform/observability/       # 관측성 스택 Application
argocd/root-app.yaml, apps/   # App of Apps
```

---

## 다른 레포와의 연결

- IRSA Role ARN, Loki 버킷, Cognito User Pool ID·issuer는 `infra` 출력값이다. 모르면 자리표시를 두고 사용자에게 알린다.
- 서비스 레포 CI가 `services/<svc>/values.yaml`의 이미지 태그를 커밋한다. 태그 키 경로를 바꾸면 `.github` 재사용 워크플로도 같이 고쳐야 한다.
- 서비스 환경 변수 이름은 각 서비스 레포의 `application.yml`과 맞춘다. 다른 담당자 레포를 고쳐야 하면 작업 전 사용자에게 알린다.

---

## 브랜치·커밋

- `main`만 쓴다. 커밋: `chore(order-service): 파드 2개로` 같은 형식 (`.github` `CONTRIBUTING.md`)
- 커밋·push·PR은 사용자가 요청할 때만

---

## 검증

```bash
helm lint charts/spring-service
helm template <svc> charts/spring-service -f services/<svc>/values.yaml | kubeconform -strict -ignore-missing-schemas -summary
actionlint   # .github/workflows가 있으면
```

# Repository Guidelines (레포지토리 가이드라인)

## 0) TL;DR (Highest Priority) (최우선 요약)
- Deliver MVP first: **register/login/JWT + board CRUD** must work end-to-end. (MVP 우선: **회원가입/로그인/JWT + 게시판 CRUD**가 처음부터 끝까지 동작해야 합니다.)
- Treat this file as source of truth for ERD/API/query/NFR. Do not change contracts silently. (ERD/API/쿼리/NFR의 기준 문서는 이 파일이며, 합의 없이 계약을 변경하지 않습니다.)
- No N+1 on post list/detail when author info is needed (use join/projection). (작성자 정보가 필요한 게시글 목록/상세에서 N+1을 금지하며 join/projection을 사용합니다.)
- `posts` uses soft delete (`deleted_at`); default reads must filter `deleted_at IS NULL`. (`posts`는 soft delete를 사용하며 기본 조회는 `deleted_at IS NULL`을 반드시 포함합니다.)
- Never log secrets: password, tokens, Authorization header, JWT secret. (비밀번호/토큰/Authorization 헤더/JWT 시크릿은 절대 로그에 남기지 않습니다.)
- Quality gate before completion: `./gradlew test`. (작업 완료 전 품질 게이트는 `./gradlew test` 통과입니다.)

## 1) Project Structure (프로젝트 구조)
- Java source: `src/main/java/com/hooqio/demo` (Java 소스 위치: `src/main/java/com/hooqio/demo`)
- Config: `src/main/resources/application.yaml` (`common`, `local`, `prod`) (설정 파일 위치: `src/main/resources/application.yaml`, 프로파일은 `common`, `local`, `prod`)
- Tests: `src/test/java/com/hooqio/demo` (테스트 위치: `src/test/java/com/hooqio/demo`)
- Local DB: `compose.yaml` (PostgreSQL, host `5433` -> container `5432`) (로컬 DB는 `compose.yaml`에서 PostgreSQL을 사용하며 호스트 `5433`이 컨테이너 `5432`로 매핑됩니다.)
- Build output: `build/` (generated; do not edit) (빌드 산출물은 `build/`이며 자동 생성물이므로 수정하지 않습니다.)

## 2) Build/Test/Run Commands (빌드/테스트/실행 명령)
- `docker compose up -d`: start PostgreSQL (`docker compose up -d`: PostgreSQL 시작)
- `docker compose down`: stop containers (`docker compose down`: 컨테이너 중지)
- `./gradlew bootRun`: run app locally (`./gradlew bootRun`: 로컬 애플리케이션 실행)
- `./gradlew test`: run tests (`./gradlew test`: 테스트 실행)
- `./gradlew clean build`: full build + tests (`./gradlew clean build`: 전체 빌드와 테스트 수행)

Recommended local flow: (권장 로컬 실행 순서:)
1. `docker compose up -d` (`docker compose up -d` 실행)
2. `./gradlew bootRun` (`./gradlew bootRun` 실행)
3. `./gradlew test` (`./gradlew test` 실행)

## 3) Coding Rules (코딩 규칙)
- Java 25, Spring Boot 4, UTF-8, 4-space indentation. (Java 25, Spring Boot 4, UTF-8, 들여쓰기 4칸을 사용합니다.)
- Naming: `PascalCase` classes, `camelCase` methods/fields, `UPPER_SNAKE_CASE` constants. (네이밍: 클래스 `PascalCase`, 메서드/필드 `camelCase`, 상수 `UPPER_SNAKE_CASE`)
- Package names lowercase (`com.hooqio.demo...`). (패키지명은 소문자만 사용합니다.)
- Constructor injection only (no field injection). (생성자 주입만 사용하고 필드 주입은 금지합니다.)
- Do not expose Entity directly in API; use DTOs. (API에 Entity를 직접 노출하지 말고 DTO를 사용합니다.)
- Environment-specific values only via profile/env vars (`DB_URL`, `DB_USER`, `DB_PASSWORD`, `JWT_SECRET`). (환경별 값은 프로파일/환경변수로만 주입합니다.)

## 4) MVP Scope (MVP 범위)
### In (포함)
- Auth: register, login, refresh, logout (refresh revoke/rotation recommended) (인증: 회원가입, 로그인, 재발급, 로그아웃을 포함하며 refresh 철회/회전을 권장합니다.)
- User: `GET /api/v1/users/me` (`PATCH /me` optional) (사용자: `GET /api/v1/users/me` 필수, `PATCH /me` 선택)
- Board: create/list/detail/update/delete (soft delete), pagination + sort (게시판: 생성/목록/상세/수정/삭제(soft delete), 페이지네이션과 정렬 포함)
- Post update/delete permission: author only (ADMIN exception optional) (게시글 수정/삭제 권한은 작성자 본인만, ADMIN 예외는 선택)

### Out (제외)
- Comments, likes, attachments, realtime notifications, advanced search (댓글/좋아요/첨부/실시간 알림/고급 검색은 MVP 범위에서 제외)

## 5) Module Boundary (Modular Monolith) (모듈 경계)
- `common`: config/security/exception/response envelope (`common`: 설정/보안/예외/응답 공통 규격)
- `auth`: login/token/auth flow (`auth`: 로그인/토큰/인증 흐름)
- `user`: user domain (`user`: 사용자 도메인)
- `board`: post domain (`board`: 게시글 도메인)

Dependency rule: (의존 규칙:)
- feature modules depend on `common` only. (기능 모듈은 `common`에만 의존합니다.)
- `board` persists `author_id` FK and resolves author via query join/projection. (`board`는 `author_id` FK를 저장하고 작성자 정보는 조회 시 join/projection으로 해결합니다.)

## 6) Data Model (PostgreSQL + Flyway) (데이터 모델)
- `users (1) - (N) posts` (`users` 1:N `posts`)
- `users (1) - (N) refresh_tokens` (`users` 1:N `refresh_tokens`)
- Required invariants: (필수 불변조건:)
- `email`, `username` unique (`email`, `username`은 유니크)
- password stored as BCrypt hash only (비밀번호는 BCrypt 해시만 저장)
- refresh token raw value never stored; store `token_hash` only (refresh token 원문 저장 금지, `token_hash`만 저장)
- soft deleted posts: `deleted_at IS NOT NULL` (soft delete된 게시글은 `deleted_at IS NOT NULL`)

Schema changes must go through Flyway migrations only. (스키마 변경은 반드시 Flyway 마이그레이션으로만 수행합니다.)

## 7) Query Patterns (쿼리 패턴)
- Post list: `deleted_at IS NULL`, sort by `created_at DESC, id DESC`, page/size. (게시글 목록은 `deleted_at IS NULL` 조건, `created_at DESC, id DESC` 정렬, page/size를 사용합니다.)
- Include author via join/projection in one query (plus count query if needed). (작성자 정보는 join/projection으로 1회 조회하고 필요 시 count 쿼리를 추가합니다.)
- Post update/delete should include ownership in `WHERE` and check affected rows. (게시글 수정/삭제는 `WHERE`에 작성자 조건을 포함하고 affected rows를 확인합니다.)
- Login: find by unique email; update `last_login_at` on success (recommended). (로그인은 유니크 email로 조회하고 성공 시 `last_login_at` 갱신을 권장합니다.)

## 8) API Contract (Base `/api/v1`) (API 계약)
- Success: `{ "data": ... }` (성공 응답 형식: `{ "data": ... }`)
- Error: (에러 응답 형식:)
```json
{
  "error": {
    "code": "SOME_ERROR_CODE",
    "message": "Human readable message",
    "details": []
  }
}
```
- Auth header: `Authorization: Bearer <accessToken>` (인증 헤더: `Authorization: Bearer <accessToken>`)
- JWT claims: `sub`, `role`, `iat`, `exp` (JWT 클레임: `sub`, `role`, `iat`, `exp`)
- TTL guidance: access 900s, refresh 1209600s (권장 TTL: access 900초, refresh 1209600초)

Endpoints: (엔드포인트:)
- `POST /auth/register` (`POST /auth/register`)
- `POST /auth/login` (`POST /auth/login`)
- `POST /auth/refresh` (`POST /auth/refresh`)
- `POST /auth/logout` (`POST /auth/logout`)
- `GET /users/me` (`GET /users/me`)
- `PATCH /users/me` (optional) (`PATCH /users/me`, 선택)
- `POST /posts` (`POST /posts`)
- `GET /posts?page=0&size=20` (max size 100) (`GET /posts?page=0&size=20`, size 최대 100)
- `GET /posts/{postId}` (`GET /posts/{postId}`)
- `PATCH /posts/{postId}` (`PATCH /posts/{postId}`)
- `DELETE /posts/{postId}` (soft delete) (`DELETE /posts/{postId}`, soft delete)

## 9) NFR (비기능 요구사항)
- p95 latency targets: (p95 지연시간 목표:)
- list/detail < 200ms (목록/상세 < 200ms)
- write ops < 300ms (쓰기 작업 < 300ms)
- login < 400ms (로그인 < 400ms)
- Security: (보안:)
- BCrypt passwords (비밀번호 BCrypt 해싱)
- hashed refresh tokens only (refresh token은 해시만 저장)
- no sensitive logs (민감정보 로그 금지)
- HTTPS required in production (운영 환경 HTTPS 필수)
- Scalability: stateless JWT-ready design for horizontal scale. (확장성: JWT 기반 무상태 구조로 수평 확장 가능해야 합니다.)

## 10) Spring/JPA Defaults (Spring/JPA 기본값)
- `spring.jpa.open-in-view=false` (`spring.jpa.open-in-view=false` 유지)
- Use validation limits (e.g., `username<=50`, `title<=200`, `size<=100`) (검증 제한을 적용합니다. 예: `username<=50`, `title<=200`, `size<=100`)
- Remove unnecessary manual dialect config when auto-detection works. (자동 감지가 동작하면 불필요한 수동 dialect 설정은 제거합니다.)

## 11) Commit/PR Guidelines (커밋/PR 가이드)
- Commit prefixes: `feat:`, `fix:`, `refactor:`, `test:`, `docs:` (커밋 접두어: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`)
- Keep commits scoped to one concern. (커밋은 단일 관심사로 작게 유지합니다.)
- PR must include: (PR에는 다음이 포함되어야 합니다:)
- What changed (무엇을 변경했는지)
- Why (왜 변경했는지)
- Test evidence (`./gradlew test`) (테스트 근거: `./gradlew test`)
- Config impacts (DB/profile/port/JWT) (설정 영향: DB/profile/port/JWT)

## 12) Definition of Done (완료 기준)
- DB starts with `docker compose up -d` (DB가 `docker compose up -d`로 기동됨)
- Flyway initializes schema automatically (Flyway가 스키마를 자동 초기화함)
- `./gradlew test` passes locally (and CI if available) (`./gradlew test`가 로컬(및 CI)에서 통과함)
- Core flow reproducible: (핵심 플로우가 재현 가능해야 함:)
- register -> login -> create post -> list -> detail -> update -> delete -> verify excluded (회원가입 -> 로그인 -> 작성 -> 목록 -> 상세 -> 수정 -> 삭제 -> 목록 제외 확인)
- Health endpoint operational (e.g., `/actuator/health`) (헬스체크 엔드포인트가 정상 동작함. 예: `/actuator/health`)

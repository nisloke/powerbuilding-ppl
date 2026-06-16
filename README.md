# Powerbuilding PPL 일지

주 6회 Push/Pull/Legs 파워빌딩 **날짜별 트레이닝 일지**. 단일 `index.html` + Supabase(본인 데이터만) 백엔드. GitHub Pages 정적 호스팅.

**라이브:** https://nisloke.github.io/powerbuilding-ppl/

## 즉시 사용 (4단계)

1. **DB 생성** — Supabase 프로젝트의 **SQL Editor**에 [`schema.sql`](./schema.sql) 전체를 붙여넣고 **Run**. (테이블·RLS·권한 자동 생성, 재실행 안전)
2. **가입 즉시 사용** — Supabase → **Authentication → Sign In / Providers → Email** 에서 **“Confirm email” 끄기** (메일 확인 없이 바로 로그인).
3. **키 확인** — Supabase → **Project Settings → API** 에서 `Project URL` 과 `anon public` 키 복사.
4. **앱 열기** — 위 라이브 URL 접속 → 최초 1회 URL·anon 키 붙여넣기 → **회원가입**(페코·뭉이 각자) → 끝. 두 폰에서 각자 로그인하면 본인 기록만 보입니다.

> `anon public` 키는 공개돼도 안전합니다. 데이터 보호는 **RLS**(본인 행만)가 담당하며, `service_role` 키는 절대 클라이언트에 넣지 않습니다.

## 기록되는 내용 (날짜별)

- **세션:** 날짜 · 운동(P/P/L) · 주차(S/H) · 숙련도 · 컨디션(😣😐😀) · 메모 · 체중 · 수면 · 디로드 표시
- **종목별:** 무게 · 반복 · RIR · 종목 메모 · (A/B 선택 시) 실제 변형
- **자동 계산:** e1RM(고반복 12회 캡 추정) · 종목별 최고기록 · 날짜별 히스토리

## 특징

- **오프라인 우선:** 로컬 캐시 먼저 렌더 → 온라인 시 동기화. 헬스장 와이파이가 끊겨도 입력 가능(재접속 시 자동 전송).
- **정직한 저장 상태:** 저장됨 / 오프라인 저장됨 / 저장 실패 구분.
- **벽시계 기반 휴식 타이머** + 알림음/진동(백그라운드 드리프트 없음).

## 설정값을 코드에 고정하려면(선택)

`index.html` 상단 `HARDCODED` 에 `url`·`anonKey`를 넣으면 최초 설정 화면을 건너뜁니다.

## 배포 갱신

```
git add -A && git commit -m "update" && git push
```
GitHub Pages가 ~1분 내 자동 반영.

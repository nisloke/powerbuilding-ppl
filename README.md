# Powerbuilding PPL 일지

주 6회 Push/Pull/Legs 파워빌딩 **날짜별 트레이닝 일지**. 단일 `index.html` + **Firebase**(Auth + Firestore, 본인 데이터만) 백엔드. GitHub Pages 정적 호스팅. 서버·빌드 없음.

**라이브:** https://nisloke.github.io/powerbuilding-ppl/

## 즉시 사용 (Firebase 설정)

1. **프로젝트 생성** — https://console.firebase.google.com → **프로젝트 추가**. (Google Analytics는 꺼도 됨)
2. **웹 앱 등록** — 프로젝트 개요 → `</>` (웹) 추가 → 앱 닉네임 입력 → 표시되는 **`firebaseConfig` 객체 복사**.
3. **Authentication** → 시작하기 → **Google** 공급자 **사용 설정** (지원 이메일 선택만 하면 됨).
4. **Firestore Database** → 데이터베이스 만들기 → 위치 `asia-northeast3 (Seoul)` → **프로덕션 모드**로 생성 → **규칙(Rules)** 탭에 [`firestore.rules`](./firestore.rules) 내용 붙여넣고 **게시**.
5. **승인 도메인** — Authentication → Settings → **Authorized domains** 에 `nisloke.github.io` 추가.
6. **화이트리스트** — `index.html` 상단 `ALLOW` 배열에 허용할 Google 이메일(페코·뭉이)을 넣음. 그 외 계정은 로그인해도 자동 로그아웃됨. (별도 계정 생성 불필요 — 각자 Google로 첫 로그인 시 자동 생성)
7. **config 적용** — 2번에서 복사한 config를 `index.html` 상단 `FB_CONFIG`에 넣고 푸시. (비워두면 앱 첫 화면에서 직접 붙여넣기 가능)

> `apiKey` 등 Firebase config는 클라이언트에 노출되도록 설계된 **공개 값**이라 코드/공개 리포에 들어가도 안전합니다. 데이터 보호는 **Firestore 보안 규칙**(본인 `users/{uid}`만)이 담당합니다. 관리자(Admin) 키는 절대 클라이언트에 넣지 않습니다.

## 데이터 모델 (Firestore)

```
users/{uid}/sessions/{YYYY-MM-DD_dayType}
  { date, dayType, week_block, level_mode, condition, memo,
    bodyweight_kg, sleep_hours, is_deload, updatedAt,
    entries: { "bench_flat": {w,r,rir,note,name}, ... } }   // 키 = 종목 id(stable exerciseId)
```

- **세션 = 날짜+운동 1문서**, 종목 기록은 그 문서의 `entries` 맵에 임베드(하루치 1읽기/1쓰기).
- **entries 키 = 종목 id(`exerciseId`)**. ⚠️ **id는 APPEND-ONLY** — 한 번 쓴 id는 변경·재사용 금지(과거 기록이 다른 종목에 오연결됨). 새 종목은 새 id로만. 종목 배열 순서는 자유(키가 인덱스가 아니라 id라서).
- **과거 호환**: 옛 기록은 키가 배열 인덱스(`push-0`)였음 → `LEGACY_MAP` + 종목명 폴백으로 읽을 때 자동 정규화(비파괴, 손실 0).
- **본인 데이터만**: 로그인 신원(`uid`)으로 격리 — RLS 대신 Firestore 보안 규칙.
- e1RM·최고기록(PR)·추세는 저장하지 않고 행을 읽어 **클라이언트에서 계산**(고반복 12회 캡).

## 프로그램 구조 (DAYS / PLAN)

- **운동 DB = `index.html`의 `DAYS` 상수**(JS 내장). 종목마다 `id`·`muscle`·`slot`·`pattern`·`sq`(영상 검색어) 메타 보유. **종목 편집은 코드 PR로만**(부부가 같은 단일 프로그램 공유 — 개인별 커스터마이즈 없음, 의도된 단순성).
- **`PLAN`**: 부위별 `main`(직렬·3분 휴식) / `ss`(슈퍼세트 페어) / `solo`(단독) / `order`(표시 순서).
- **슈퍼세트 안전 규칙**: 같은 근육·코어는 절대 묶지 않음(불가리안+케틀벨스윙 같은 사고 방지). 로드 시 `validateProgram`이 order 누락/중복·같은근육·코어 슈퍼세트를 **런타임 검증 → UI 배너 + 콘솔 에러**로 경고.
- **영상**: 모든 종목·워밍업을 **@DeltaBolic 채널 검색**(`sq` 검색어)으로 연결. 특정 영상 id(`vid`)가 있으면 직접 쇼츠 링크.

## 특징

- **오프라인 우선**: Firestore 영구 캐시(IndexedDB)로 오프라인 읽기/쓰기 → 재접속 시 자동 동기화. 헬스장 신호가 약해도 입력 가능.
- **세션 유지**: Firebase Auth가 토큰을 자동 갱신·영속화 → 한 번 로그인하면 계속 유지.
- **벽시계 기반 휴식 타이머** + 알림음/진동.

## 배포 갱신

```
git add -A && git commit -m "update" && git push
```
GitHub Pages가 ~1분 내 자동 반영.

# 데이터베이스 관리 문서 (DBA Documentation)

이 디렉토리는 SNS Automation 프로젝트의 모든 데이터베이스 스키마 정보와 변경 이력을 관리합니다.

---

## 📁 문서 구조

```
/docs/dba/
├── README.md                                    # 이 문서
├── CHANGELOG.md                                 # 모든 스키마 변경 이력
├── init.sql                                     # 최신 전체 스키마 DDL
└── v{version}_{description}.md                  # 버전별 상세 변경 문서
    ├── v1.0.0_separate-posts-and-triggers.md    # 포스트와 트리거 분리
    └── ...
```

---

## 📖 문서 파일 설명

### 1. **init.sql**
- 현재 프로덕션 데이터베이스 스키마의 전체 DDL
- 모든 승인된 변경사항이 반영된 최신 상태
- 새로운 환경 구축 시 이 파일을 실행하여 데이터베이스 초기화

**사용 예:**
```bash
mysql -u root -p < docs/dba/init.sql
```

### 2. **CHANGELOG.md**
- 모든 데이터베이스 변경사항의 요약 목록
- 버전, 날짜, 변경 유형, 영향도 포함
- 시맨틱 버저닝 사용 (v1.0.0, v1.1.0, v2.0.0 등)

### 3. **v{version}_{description}.md**
- 각 스키마 변경의 상세 문서
- 변경 근거, DDL 문, 마이그레이션 노트, 영향 분석 포함
- 파일명 규칙: `v{version}_{kebab-case-description}.md`

**예시:**
- `v1.0.0_separate-posts-and-triggers.md`
- `v1.1.0_add-notification-table.md`
- `v2.0.0_refactor-user-structure.md`

---

## 🔄 스키마 변경 프로세스

### 1. 변경 제안
1. 요구사항 분석
2. 기존 문서(`/docs/dba`) 검토
3. 기존 스키마(`init.sql`) 확인
4. 변경안 설계

### 2. 문서화
1. 새 버전 번호 결정 (시맨틱 버저닝)
2. `v{version}_{description}.md` 파일 생성
3. 상세 변경사항, DDL, 근거, 영향 분석 작성
4. `CHANGELOG.md`에 요약 추가
5. `init.sql` 업데이트 (전체 DDL 반영)

### 3. 검토 및 승인
1. DBA 검토
2. 개발팀 영향 분석
3. 마이그레이션 계획 수립
4. 승인

### 4. 실행
1. 개발 환경 테스트
2. 스테이징 환경 적용
3. 프로덕션 마이그레이션
4. 롤백 계획 준비

---

## 📋 현재 스키마 개요

### 테이블 목록

| 테이블명 | 설명 | 주요 관계 |
|---------|------|----------|
| `tb_users` | 사용자 정보 | - |
| `tb_user_passwords` | 비밀번호 이력 | tb_users (1:N) |
| `tb_user_oauth` | SNS 연동 정보 | tb_users (1:1) |
| `tb_instagram_posts` | 인스타그램 포스트 | tb_users (1:N) |
| `tb_post_triggers` | 포스트별 트리거 | tb_instagram_posts (1:N) |
| `tb_trigger_execute_history` | 트리거 실행 이력 | tb_post_triggers (1:N) |

### 테이블 관계도

```
tb_users (사용자)
  ├─→ 1:N → tb_user_passwords (비밀번호 이력)
  ├─→ 1:1 → tb_user_oauth (SNS 연동)
  └─→ 1:N → tb_instagram_posts (인스타그램 포스트)
                ├─→ 1:N → tb_post_triggers (포스트별 트리거)
                │            ├─→ 1:N → tb_trigger_execute_history (실행 이력)
                │            └─→ FK: user_seq → tb_users.seq
                └─→ FK: user_seq → tb_users.seq
```

---

## 🎯 버전 관리 규칙

### 시맨틱 버저닝 (Semantic Versioning)

형식: `v{MAJOR}.{MINOR}.{PATCH}`

- **MAJOR (v2.0.0)**: 기존 데이터나 API와 호환되지 않는 주요 변경
  - 예: 테이블 삭제, 컬럼 타입 변경 (데이터 손실 가능), 외래 키 구조 재설계

- **MINOR (v1.1.0)**: 기존과 호환되는 기능 추가
  - 예: 새 테이블 추가, 새 컬럼 추가 (nullable), 인덱스 추가

- **PATCH (v1.0.1)**: 기존 구조 내에서의 미세 조정
  - 예: 인덱스 최적화, 컬럼 코멘트 수정, 기본값 변경

---

## ⚠️ 주의사항

### DDL 실행 시
- **중요**: 모든 DDL 실행은 사용자의 책임입니다.
- 반드시 개발 환경에서 충분히 테스트 후 프로덕션 적용
- 프로덕션 적용 전 전체 데이터베이스 백업 필수
- 외래 키 제약조건으로 인한 순서 의존성 주의

### 마이그레이션 시
- 서비스 중단 시간 사전 공지
- 롤백 계획 반드시 준비
- 트랜잭션으로 원자성 보장 권장
- 데이터 유실 방지를 위한 검증 단계 필수

### 문서 작성 시
- 기존 문서 반드시 검토 (중복 방지)
- 변경 근거 명확히 기술
- 영향 받는 API 및 코드 명시
- 마이그레이션 스크립트 제공

---

## 📚 참고 자료

### 관련 문서
- [프로젝트 README](/readme.md)
- [API 문서](/api/README.md)
- [Sequelize 모델](/api/src/models)

### 외부 링크
- [MySQL 8.0 Reference Manual](https://dev.mysql.com/doc/refman/8.0/en/)
- [Semantic Versioning](https://semver.org/lang/ko/)
- [Database Design Best Practices](https://www.guru99.com/database-design.html)

---

## 🔍 빠른 검색

### 특정 테이블 관련 변경 찾기
```bash
# CHANGELOG에서 테이블명 검색
grep -i "tb_users" docs/dba/CHANGELOG.md

# 모든 버전 문서에서 검색
grep -r "tb_users" docs/dba/v*.md
```

### 특정 버전 찾기
```bash
# v1.0.0 관련 문서
cat docs/dba/v1.0.0_*.md
```

### 최신 스키마 확인
```bash
# init.sql 확인
cat docs/dba/init.sql

# 특정 테이블 DDL만 확인
grep -A 30 "CREATE TABLE \`tb_users\`" docs/dba/init.sql
```

---

## 📞 문의

스키마 변경 관련 문의사항은 DBA 팀 또는 프로젝트 리더에게 연락하세요.

**문서 버전:** 1.0.0
**최종 수정일:** 2025-12-29

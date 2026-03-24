# Boss 워크스페이스

## 기본 규칙
- 모든 응답과 노트는 한국어로 작성
- 옵시디언 노트 저장 시 PARA 구조 준수
- 날짜는 항상 `TZ=Asia/Seoul date` 명령으로 동적 계산 (하드코딩 금지)

## 옵시디언 볼트 구조 (PARA)
```
0_Inbox_fleeting/     ← 빠른 메모, 미분류 노트
1_Projects_성과목표/  ← 트레이딩/, 마케팅기획/, 책연구/
2_Areas_계속_책임/    ← 손실종목/, bkit-system/, 시장재료/, 종목재료메모/
3_Resouces_문헌_관심_참고/ ← 도구 가이드, 리서치 자료
4_Archives_완료_연결/ ← 완료된 프로젝트
5_Permanent_Notes/    ← 영구 노트
Stock Analysis/       ← 증시브리핑, 종목분석
DISHSUM 쇼핑몰/       ← 스마트스토어 상품관리
키움증권 HTS/         ← HTS 매뉴얼
Periodic_2026/        ← 주기적 리뷰, 볼트 정리 기록
Clippings/            ← 웹 클리핑
```

## MCP 서버
- **Obsidian MCP**: 볼트 읽기/쓰기/검색
- **Naver Search MCP**: 뉴스, 블로그, 카페, 쇼핑, 웹문서, DataLab
- **Exa Search MCP**: 영문 심층 검색, find_similar, get_contents
- **Pinecone**: naver-stock-themes, korean-stock-news 인덱스
- **Sequential Thinking**: 복잡한 분석 시 사고 구조화

## 에이전트 팀 단축 명령어

아래 키워드가 입력되면 해당 에이전트 팀을 자동으로 스폰하라.

### "증시 분석" 또는 "증시 브리핑"
→ 에이전트 팀 3명 스폰:
- **시장수급**: Exa + 네이버 search_news로 코스피/코스닥 지수, 외국인/기관 수급 수집
- **테마종목**: 네이버 search_news + search_webkr로 급등/급락 테마, 특징주 TOP 5 조사
- **글로벌**: Exa로 미국/중국 증시, 환율, 원자재 동향 수집
- Team Lead: 종합 후 obsidian_append_content로 "Stock Analysis/증시브리핑_{날짜}.md" 저장
- 대화창에는 5줄 요약만 출력

### "{종목명} 분석" 또는 "{종목명} 어때"
→ 에이전트 팀 3명 스폰:
- **단기뉴스**: 네이버 search_news 4회 (주가/공시/외국인매매/전망) + 핵심 기사 3개 WebFetch
- **동반종목**: 네이버 search_webkr 3회 + search_news 1회로 같은 테마 동반급등주 TOP 5
- **산업분석**: 네이버 search_news 3회 + search_blog 1회 + Exa 3회로 실적/목표가/산업맥락
- Team Lead: 투자포인트 5가지 도출 → "0_Inbox_fleeting/{종목명}_분석리포트_{날짜}.md" 저장
- 대화창에는 핵심 1줄 + 동반급등 TOP 3만 출력

### "Inbox 정리" 또는 "인박스 정리"
→ 에이전트 팀 2명 스폰:
- **분류**: 0_Inbox_fleeting/ 전체 파일을 batch로 읽고 PARA 폴더별 분류 판정
  - 종목 분석 → Stock Analysis/
  - 쇼핑몰 관련 → DISHSUM 쇼핑몰/
  - 도구/설정 → 3_Resouces_문헌_관심_참고/
  - 개인 메모 → 5_Permanent_Notes/
  - 무제/빈 파일 → 삭제 후보
- **실행**: 분류 결과 검증 + 중복 확인 + 최종 액션플랜 작성
- Team Lead: "0_Inbox_fleeting/📋_Inbox정리_액션플랜_{날짜}.md"에 저장
- 실제 이동/삭제는 Boss 확인 후 "실행해줘"라고 하면 진행

### "볼트 정리" 또는 "볼트 점검"
→ 에이전트 팀 3명 스폰:
- **Inbox정리**: 0_Inbox_fleeting/ 파일 분류 + 이동 제안
- **종목노트점검**: Stock Analysis + Inbox의 분석 노트 품질 등급(A/B/C) + 중복 식별
- **구조점검**: PARA 폴더별 파일 수 통계 + 루트 방치 파일 + 고아 노트 탐지
- Team Lead: "Periodic_2026/볼트정리_{날짜}.md"에 종합 리포트 저장

### "종목 리뷰" 또는 "분석 리뷰"
→ 에이전트 팀 2명 스폰:
- **노트점검**: Stock Analysis + Inbox 종목분석 노트 전수 품질 체크 (frontmatter/태그/출처/mermaid)
- **인사이트**: 가장 많이 분석한 종목 TOP 10, 반복 테마, 월별 관심 변화, 다음 주 워치리스트
- Team Lead: "Stock Analysis/종목분석_주간리뷰_{날짜}.md"에 저장

### "상품 등록 {상품명}" 또는 "{상품명} 등록"
→ 에이전트 팀 3명 스폰:
- **경쟁분석**: 네이버 search_shop으로 경쟁 상품 가격/제목/리뷰 패턴 조사
- **상품기획**: 경쟁분석 결과로 상품명 3개 후보 + SEO 키워드 20개 + 상세설명 초안
- **마케팅**: 네이버 search_blog + datalab으로 블로그 키워드 + SNS 해시태그 + 1주 캘린더
- Team Lead: "DISHSUM 쇼핑몰/{상품명}_등록가이드_{날짜}.md"에 저장

### "루트 정리" 또는 "루트 청소"
→ 에이전트 팀 2명 스폰:
- **루트정리**: 볼트 루트 방치 파일(무제.md 등) 내용 확인 → 분류/삭제 판정
- **폴더통합**: 중복 폴더(0.Inbox vs 0_Inbox) 통합 + PARA 하위 구조 점검 + 개선안
- Team Lead: "Periodic_2026/볼트_루트정리_{날짜}.md"에 저장

## 저장 규칙
- 종목 분석: `0_Inbox_fleeting/{종목명}_분석리포트_{날짜}.md`
- 증시 브리핑: `Stock Analysis/증시브리핑_{날짜}.md`
- 볼트 정리: `Periodic_2026/볼트정리_{날짜}.md`
- 상품 등록: `DISHSUM 쇼핑몰/{상품명}_등록가이드_{날짜}.md`
- 모든 노트에 frontmatter (tags, date) 포함

## 대화창 출력 규칙
- 에이전트 팀 작업 결과는 항상 5줄 이내 요약만 출력
- 전체 내용은 옵시디언에서 확인하도록 안내
- 이모티콘으로 구분: 📊증시 📈종목 🛒상품 📝정리 🔀종합

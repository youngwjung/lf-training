# 실습 환경 생성용 테라폼 코드

LFS458 및 LFD459 실습 환경 생성을 위한 테라폼 코드

## 실습 환경 생성

`number_of_stduents` 변수값에 참가 인원을 넣고 테라폼 코드 실행
 ```
 e.g.
 terraform apply -var="number_of_stduents=10"
 ```
 
## 생성된 실습환경 정보 확인

Output에 저장된 정보 출력
```
terraform output
```
# 실습 환경 생성용 테라폼 코드

LFS458 및 LFD459 실습 환경 생성을 위한 테라폼 코드

## 실습 환경 생성

1. Terraform 설치 및 AWS CLI를 통해서 AWS 자격증명 등록

2. Terraform 환경 생성
```
terraform init 
```

3. 인프라 생성
```
terraform apply --auto-approve
```

## 생성된 실습환경 정보 확인

1. Output에 저장된 정보 출력
```
terraform output
```
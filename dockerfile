### Dockerfile(docker build 시 사용되는파일)

# 파이썬 이미지 사용
FROM python:3.13-alpine

# 메인테이너(관리자) 정보
LABEL maintainer="oscar2272"
# 파이썬 출력 버퍼링 비활성화
ENV PYTHONUNBUFFERED 1

# docker-compose에서 DEV의 값을 덮어씀 (따라서 해당 ARG는 docker build 시 사용되는 값)
ARG DEV=false
# 종속성 파일 및 앱 복사
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
COPY ./app /app
# 작업 디렉토리(컨테이너 내부의 앱) 설정 (docker run 시 작업 디렉토리 설정)
WORKDIR /app
# 포트 노출
EXPOSE 8000

# 가상환경 생성 및 종속성 설치
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client && \
    apk add --update --no-cache --virtual .tmp-build-deps \
      build-base postgresql-dev musl-dev && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    # dev 환경이면 dev.txt 추가 설치
    if [ $DEV = "true" ]; \
      then /py/bin/pip install -r /tmp/requirements.dev.txt; \
    fi && \
    rm -rf /tmp && \
    apk del .tmp-build-deps && \
    # docker 컨테이너 내부에서 사용자 생성
    adduser \
      --disabled-password \
      # 홈 디렉토리 생성 안함
      --no-create-home \
      # 사용자 이름
      django-user

# 가상환경 경로 환경변수 설정
ENV PATH="/py/bin:$PATH"
# 이후 모든 명령어는 django-user 권한으로 실행
USER django-user
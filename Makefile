SHELL = $(PWD)/shell_with_env -o pipefail

all: .env create-session

# Generate environment variables for Docker Compose
.env: template.env out/docker_image out/session_id
	SESSION=$(shell cat out/session_id) \
	envsubst '$$DEVICE $$SESSION' < "$<" > "$@"
	cat $@

# Upload session to the CAS
create-session: out/session.yml out/scone-session-key.pem out/scone-session.pem
	curl -k -s \
	--cert out/scone-session.pem  \
	--key out/scone-session-key.pem  \
	--data-binary @out/session.yml \
	https://$$SCONE_CAS_ADDR:8081/v1/sessions

# Create CAS session file from the template
out/session.yml: session-template.yml out/session_id
	SESSION=$(shell cat out/session_id) \
	FSPF_TAG=$(shell cat out/docker.log | grep 'Encrypted file system protection file'  | awk '{print $$9}') \
	FSPF_KEY=$(shell cat out/docker.log | grep 'Encrypted file system protection file'  | awk '{print $$11}') \
	envsubst '$$SESSION $$MRENCLAVE $$FSPF_TAG $$FSPF_KEY' < "$<" > "$@"

# Generate random session ID
out/session_id:
	echo "Crypt4GHEncryptProcessExample-$$RANDOM-$$RANDOM-$$RANDOM" > $@

# Create certificate to interact with the CAS
out/scone-session-key.pem: out/scone-session.pem

out/scone-session.pem:
	openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/CN=example.scontain.com" \
	-out out/scone-session.pem \
	-keyout out/scone-session-key.pem

# Build the service Docker image
out/docker_image: Dockerfile requirements.txt $(shell find ./app -type f -name '*')
	rm -f $@
	docker build -t $$CRYPT4GH_IMAGE --build-arg CACHE_DATE="$$(date +%s)" . | tee out/docker.log
	echo $$CRYPT4GH_IMAGE > $@

clean:
	@rm -f ./out/*

.PHONY: all clean create-session out/session_id .env

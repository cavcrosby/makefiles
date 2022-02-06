# recursive variables

# targets
DOCKER_ANSIBLE_INVENTORY = docker-ansible-inventory
DOCKER_IMAGE = docker-image
DOCKER_TEST_DEPLOY = docker-test-deploy
DOCKER_TEST_DEPLOY_DISMANTLE = docker-test-deploy-dismantle
DOCKER_IMAGE_CLEAN = docker-image-clean

# executables
DOCKER = docker
GAWK = gawk
GIT = git
docker_executables = \
	${DOCKER}\
	${GIT}\
	${GAWK}

# sane defaults
export CONTAINER_NAME = jenkins-base
export CONTAINER_NETWORK = jbc1
export CONTAINER_VOLUME = jenkins_home:/var/jenkins_home
ANSIBLE_INVENTORY_PATH = ./localhost
DOCKER_REPO = cavcrosby/jenkins-base
DOCKER_CONTEXT_TAG = latest
DOCKER_LATEST_VERSION_TAG = $(shell ${GIT} describe --tags --abbrev=0)
DOCKER_VCS_LABEL = tech.cavcrosby.jenkins.base.vcs-repo=https://github.com/cavcrosby/jenkins-docker-base

ifdef IMAGE_RELEASE_BUILD
	DOCKER_BUILD_OPTS = \
		--tag \
		${DOCKER_REPO}:${DOCKER_CONTEXT_TAG} \
		--tag \
		${DOCKER_REPO}:${DOCKER_LATEST_VERSION_TAG}
else
	DOCKER_CONTEXT_TAG = test
	DOCKER_BUILD_OPTS = \
		--tag \
		${DOCKER_REPO}:${DOCKER_CONTEXT_TAG}
endif
export DOCKER_CONTEXT_TAG

.PHONY: ${DOCKER_ANSIBLE_INVENTORY}
${DOCKER_ANSIBLE_INVENTORY}:
>	eval "$${ANSIBLE_INVENTORY}" > "${ANSIBLE_INVENTORY_PATH}"

.PHONY: ${DOCKER_IMAGE}
${DOCKER_IMAGE}:
>	${DOCKER} build \
        --build-arg BRANCH="$$(${GIT} branch --show-current)" \
        --build-arg COMMIT="$$(${GIT} show --format=%h --no-patch)" \
        ${DOCKER_BUILD_OPTS} \
        .

# meant to be used solely for testing a image on my local development machine
.PHONY: ${DOCKER_TEST_DEPLOY}
${DOCKER_IMAGE_TEST_DEPLOY}:
>	 ${ANSIBLE_PLAYBOOK} --inventory "${ANSIBLE_INVENTORY_PATH}" "./create_container.yml" --ask-become-pass

.PHONY: ${DOCKER_TEST_DEPLOY_DISMANTLE}
${DISMANTLE}:
>	${DOCKER} rm --force "${CONTAINER_NAME}"

ifndef SKIP_DOCKER_NETWORK
>	${DOCKER} network rm "${CONTAINER_NETWORK}"
endif

ifndef SKIP_DOCKER_VOLUME
>	${DOCKER} volume rm --force "$$(echo "${CONTAINER_VOLUME}" \
		| ${GAWK} --field-separator ':' '{print $$1}')"
endif

.PHONY: ${DOCKER_IMAGE_CLEAN}
${DOCKER_IMAGE_CLEAN}:
>	${DOCKER} rmi ${DOCKER_REPO}:test $$(${DOCKER} images \
		--filter label="${DOCKER_VCS_LABEL}" \
		--filter dangling="true" \
		--format "{{.ID}}")

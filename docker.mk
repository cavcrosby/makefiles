# recursive variables

# targets
DOCKER_ANSIBLE_INVENTORY = docker-ansible-inventory
DOCKER_IMAGE = docker-image
DOCKER_TEST_DEPLOY = docker-test-deploy
DOCKER_TEST_DEPLOY_DISMANTLE = docker-test-deploy-dismantle
DOCKER_PUBLISH = docker-publish
DOCKER_IMAGE_CLEAN = docker-image-clean

# executables
DOCKER = docker
# MONITOR(cavcrosby): going forward, executables used in at least 2 common
# makefiles and are not in a domain specific (e.g. ansible-playbook would be in
# ansible.mk) makefile should go into 'base.mk'.
GAWK = gawk
docker_executables = \
	${DOCKER}\
	${GAWK}\
	${base_executables}

# sane defaults
export CONTAINER_NAME = jenkins-base
export CONTAINER_NETWORK = jbc1
export CONTAINER_VOLUME = jenkins_home:/var/jenkins_home
ANSIBLE_INVENTORY_PATH = ./localhost
DOCKER_REPO = cavcrosby/jenkins-base
DOCKER_CONTEXT_TAG = latest
DOCKER_LATEST_VERSION_TAG = $(shell ${GIT} describe --tags --abbrev=0)
DOCKER_VCS_LABEL = tech.cavcrosby.jenkins.base.vcs-repo=https://github.com/cavcrosby/jenkins-docker-base

ifneq ($(findstring ${IMAGE_RELEASE_BUILD},${TRUTHY_VALUES}),)
	DOCKER_TARGET_IMAGES = \
		${DOCKER_REPO}:${DOCKER_CONTEXT_TAG} \
		${DOCKER_REPO}:${DOCKER_LATEST_VERSION_TAG}
else
	DOCKER_CONTEXT_TAG = test
	DOCKER_TARGET_IMAGES = \
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
        $(addprefix --tag=,${DOCKER_TARGET_IMAGES}) \
        .

.PHONY: ${DOCKER_TEST_DEPLOY}
${DOCKER_TEST_DEPLOY}:
ifneq ($(findstring ${CONTINUOUS_INTEGRATION},${TRUTHY_VALUES}),)
>	 ${ANSIBLE_PLAYBOOK} --inventory "${ANSIBLE_INVENTORY_PATH}" "./playbooks/create_container.yml"
else
>	 ${ANSIBLE_PLAYBOOK} --inventory "${ANSIBLE_INVENTORY_PATH}" "./playbooks/create_container.yml" --ask-become-pass
endif

.PHONY: ${DOCKER_TEST_DEPLOY_DISMANTLE}
${DOCKER_TEST_DEPLOY_DISMANTLE}:
>	${DOCKER} rm --force "${CONTAINER_NAME}"

ifneq ($(findstring ${SKIP_DOCKER_NETWORK},${TRUTHY_VALUES}),)
>	${DOCKER} network rm --force "${CONTAINER_NETWORK}"
endif

ifneq ($(findstring ${SKIP_DOCKER_VOLUME},${TRUTHY_VALUES}),)
>	${DOCKER} volume rm --force "$$(echo "${CONTAINER_VOLUME}" \
		| ${GAWK} --field-separator ':' '{print $$1}')"
endif

.PHONY: ${DOCKER_PUBLISH}
${DOCKER_PUBLISH}:
>	@for docker_target_image in ${DOCKER_TARGET_IMAGES}; do \
>		echo ${DOCKER} push "$${docker_target_image}"; \
>		${DOCKER} push "$${docker_target_image}"; \
>	done

.PHONY: ${DOCKER_IMAGE_CLEAN}
${DOCKER_IMAGE_CLEAN}:
>	${DOCKER} rmi --force ${DOCKER_REPO}:test $$(${DOCKER} images \
		--filter label="${DOCKER_VCS_LABEL}" \
		--filter dangling="true" \
		--format "{{.ID}}")

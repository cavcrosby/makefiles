# recursively expanded variables

# targets
ANSILINT = ansilint

# executables
ANSIBLE_GALAXY = ansible-galaxy
ANSIBLE_LINT = ansible-lint
ANSIBLE_PLAYBOOK = ansible-playbook
ANSIBLE_VAULT = ansible-vault
ansible_executables = \
	${ANSIBLE_GALAXY}\
	${ANSIBLE_LINT}\
	${ANSIBLE_PLAYBOOK}\
	${ANSIBLE_VAULT}

# sane defaults
ANSIBLE_SRC = $(shell find . \( -type f \) \
	-and \
	\( \
		\( -name '*.yaml' \) \
		-or \( -name '*.yml' \) \
	\) \
	-and ! \( -path '*.git*' \) \
)

.PHONY: ${ANSIBLE_LINT}
${ANSIBLE_LINT}:
>	@for fil in ${ANSIBLE_SRC}; do \
>		if echo $${fil} | grep --quiet '-'; then \
>			echo "make: $${fil} should not contain a dash in the filename"; \
>		fi \
>	done
>	${ANSIBLE_LINT}

# targets
ANSILINT = ansilint

# executables
ANSIBLE_LINT = ansible-lint

# sane defaults
ANSISRC = $(shell find . \( -type f \) \
	-and \( -name '*.yaml' \) \
	-or \( -name '*.yml' \) \
)

.PHONY: ${ANSILINT}
${ANSILINT}:
>	@for fil in ${ANSISRC}; do \
>		if echo $${fil} | grep --quiet '-'; then \
>			echo "make: $${fil} should not contain a dash in the filename"; \
>		fi \
>	done
>	${ANSIBLE_LINT}

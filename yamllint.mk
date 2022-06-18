# recursively expanded variables

# executables
YAMLLINT = yamllint
yamllint_executables = \
	${YAMLLINT}

# sane defaults
YAML_SRC = $(shell find . \( -type f \) \
	-and \
	\( \
		\( -name '*.yaml' \) \
		-or \( -name '*.yml' \) \
	\) \
	-and ! \( -path '*.git*' \) \
)

.PHONY: ${YAMLLINT}
${YAMLLINT}:
>	${YAMLLINT} ${YAML_SRC} 1>&2

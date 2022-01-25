include base.mk

# recursive variables
INSTALL_PATH = ${DESTDIR}${includedir}/cavcrosby-makefiles
PROJECT_TARBALL = makefiles.tar.gz
PROJECT_TARBALL_PATH = ./${PROJECT_TARBALL}

# targets
TARBALL = tarball

# simply expanded variables
src := $(shell find . \( -type f \) \
	-and \( -name '*.mk' \) \
)

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Common make targets:'
>	@echo '  ${TARBALL}            - creates a tarball containing all the makefiles'
>	@echo '  ${INSTALL}            - installs the makefiles on the current machine'
>	@echo '  ${UNINSTALL}          - removes the makefiles that were inserted by the'
>   @echo '                       ${INSTALL} target'
>	@echo '  ${CLEAN}              - removes files generated from other targets'

.PHONY: ${TARBALL}
${TARBALL}:
>	tar zcf "${PROJECT_TARBALL_PATH}" \
        --exclude=./Makefile \
        --exclude-vcs-ignores \
        ./*

.PHONY: ${INSTALL}
${INSTALL}:
>	mkdir --parents "${INSTALL_PATH}"
>	${INSTALL} ${src} "${INSTALL_PATH}"

.PHONY: ${UNINSTALL}
${UNINSTALL}:
>	rm --recursive --force "${INSTALL_PATH}"

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force "${PROJECT_TARBALL_PATH}"

include base.mk

# recursive variables
MAINTAINER_SCRIPTS_DIR_PATH = ./pkg_install
export MAKEFILES_DESTDIR = cavcrosby-makefiles
export DEPLOYDIR_PATH = /tmp/${MAKEFILES_DESTDIR}
install_path = ${DESTDIR}${includedir}/${MAKEFILES_DESTDIR}

# The following 'su' command is used to determine the target user HOME directory
# and is equivalent to the HOME env var.
export _INCLUDEDIR = $$(su --login "$${SUDO_USER}" --command "echo \$${HOME}")/.local/include

# common vars to be used in packaging maintainer scripts
_MAKEFILES_DESTDIR = $${MAKEFILES_DESTDIR}
_DEPLOYDIR_PATH = $${DEPLOYDIR_PATH}
__INCLUDEDIR = $${_INCLUDEDIR}
maintainer_scripts_vars = \
    ${_MAKEFILES_DESTDIR}\
    ${_DEPLOYDIR_PATH}\
	${__INCLUDEDIR}

# targets
DEB = deb
PUBLISH_DEB = publish-deb
MAINTAINER_SCRIPTS = maintainer-scripts

# to be (or can be) passed in at make runtime
PKG_ITERATION = 1

# executables
ENVSUBST = envsubst
FPM = fpm
GIT = git
PACKAGE_CLOUD = package_cloud
# DISCUSS(cavcrosby): some projects have 'executables' be a simply expanded variable. Is this because
# they append additional executables from the common makefiles?
executables = \
	${FPM}\
	${GIT}\
    ${PACKAGE_CLOUD}

# simply expanded variables
src := $(shell find . \( -type f \) \
	-and \( -name '*.mk' \) \
)
src_fpm_paths := $(shell find . \( -type f \) \
	-and \( -name '*.mk' \) \
    -and \( -printf '%P=${DEPLOYDIR_PATH}/%P ' \) \
)
export VERSION := $(shell ${GIT} describe --tags --abbrev=0 | sed 's/v//')

SHELL_TEMPLATE_EXT := .shtpl
shell_template_wildcard := %${SHELL_TEMPLATE_EXT}
maintainer_script_shell_templates := $(shell find . -name "*${SHELL_TEMPLATE_EXT}")

# Determines the maintainer script name(s) to be generated from the template(s).
# Short hand notation for string substitution: $(text:pattern=replacement).
_maintainer_scripts := $(maintainer_script_shell_templates:${SHELL_TEMPLATE_EXT}=)
_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))

# DISCUSS(cavcrosby): should variables be used at all in the help description, I
# believe I've wanted to transition away from using them in help descriptions
# that way altering the variables doesn't change the help description.
.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Common make targets:'
>	@echo '  ${INSTALL}            - installs the makefiles on the current machine'
>	@echo '  ${UNINSTALL}          - removes the makefiles that were inserted by the'
>   @echo '                       ${INSTALL} target'
>	@echo '  ${DEB}                - generates the project'\''s debian package(s)'
>	@echo '  ${CLEAN}              - removes files generated from other targets'
>	@echo 'Common make configurations (e.g. make [config]=1 [targets]):'
>	@echo '  PKG_ITERATION            - denotes package version of makefiles (e.g 1, 2)'

.PHONY: ${INSTALL}
${INSTALL}:
>	@mkdir --parents "${install_path}"
>	${INSTALL} ${src} "${install_path}"

.PHONY: ${UNINSTALL}
${UNINSTALL}:
>	rm --recursive --force "${install_path}"

.PHONY: ${MAINTAINER_SCRIPTS}
${MAINTAINER_SCRIPTS}: ${_maintainer_scripts}

# All maintainer scripts at the moment are assumed to have no extension hence no
# wildcard var on the target.
${MAINTAINER_SCRIPTS_DIR_PATH}/%: ${MAINTAINER_SCRIPTS_DIR_PATH}/${shell_template_wildcard}
>	${ENVSUBST} '${maintainer_scripts_vars}' < "$<" > "$@"
>   @chmod +rx "$@"

.PHONY: ${DEB}
${DEB}: ${MAINTAINER_SCRIPTS}
>   ${FPM} --output-type deb \
        --version "${VERSION}" \
        --iteration "${PKG_ITERATION}" \
        --before-install "${MAINTAINER_SCRIPTS_DIR_PATH}/preinst" \
        --after-install "${MAINTAINER_SCRIPTS_DIR_PATH}/postinst" \
        --before-remove "${MAINTAINER_SCRIPTS_DIR_PATH}/prerm" \
        ${src_fpm_paths}

.PHONY: ${PUBLISH_DEB}
${PUBLISH_DEB}:
>   ${PACKAGE_CLOUD} push cavcrosby/makefiles/debian/bullseye ./*.deb
>   ${PACKAGE_CLOUD} push cavcrosby/makefiles/ubuntu/impish ./*.deb

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force *.deb
>	rm --force ${_maintainer_scripts}

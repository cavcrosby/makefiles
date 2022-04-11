include base.mk

# recursive variables
export MAKEFILES_VARS_PATH = /etc/profile.d/cavcrosby-makefiles
MAINTAINER_SCRIPTS_DIR_PATH = ./pkg_install
export INSTALL_PATH = ${DESTDIR}${includedir}/cavcrosby-makefiles

# This variable is usually a simply expanded variable, however, I wish to delay
# eval'ing this variable in the event the 'prefix' variable changes.
src_fpm_paths = $(shell find . \( -type f \) \
	-and \( -name '*.mk' \) \
    -and \( -printf '%P=${INSTALL_PATH}/%P ' \) \
)

# common vars to be used in packaging maintainer scripts
_INSTALL_PATH = $${INSTALL_PATH}
_MAKEFILES_VARS_PATH = $${MAKEFILES_VARS_PATH}
maintainer_scripts_vars = \
    ${_INSTALL_PATH}\
    ${_MAKEFILES_VARS_PATH}

# targets
DEB = deb
PUBLISH_DEB = publish-deb
MAINTAINER_SCRIPTS = maintainer-scripts

# to be (or can be) passed in at make runtime
PKG_ITERATION = 1

# executables
ENVSUBST = envsubst
FPM = fpm
PACKAGE_CLOUD = package_cloud
executables = \
	${FPM}\
    ${PACKAGE_CLOUD}\
    ${base_executables}

# simply expanded variables
src := $(shell find . \( -type f \) \
	-and \( -name '*.mk' \) \
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
>	@mkdir --parents "${INSTALL_PATH}"
>	${INSTALL} ${src} "${INSTALL_PATH}"

.PHONY: ${UNINSTALL}
${UNINSTALL}:
>	rm --recursive --force "${INSTALL_PATH}"

.PHONY: ${MAINTAINER_SCRIPTS}
${MAINTAINER_SCRIPTS}: prefix = /usr/local
${MAINTAINER_SCRIPTS}: ${_maintainer_scripts}

# All maintainer scripts at the moment are assumed to have no extension hence no
# wildcard var on the target.
${MAINTAINER_SCRIPTS_DIR_PATH}/%: ${MAINTAINER_SCRIPTS_DIR_PATH}/${shell_template_wildcard}
>	${ENVSUBST} '${maintainer_scripts_vars}' < "$<" > "$@"
>   @chmod +rx "$@"

.PHONY: ${DEB}
${DEB}: prefix = /usr/local
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
>   ${PACKAGE_CLOUD} push cavcrosby/makefiles/ubuntu/focal ./*.deb

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force *.deb
>	rm --force ${_maintainer_scripts}

# recursively expanded variables
VIRTUALENV_PYTHON_VERSION = $(eval VIRTUALENV_PYTHON_VERSION := $$(shell pyver_selector 2> /dev/null))${VIRTUALENV_PYTHON_VERSION}

# targets
PRE_PYENV_SETUP = pre-pyenv-setup
PYENV_VIRTUALENV = pyenv-virtualenv
PYENV_POETRY_VIRTUALENV_SETUP = pyenv-poetry-virtualenv-setup
PYENV_REQUIREMENTS_VIRTUALENV_SETUP = pyenv-requirements-virtualenv-setup
PYENV_POETRY_SETUP = pyenv-poetry-setup
PYENV_REQUIREMENTS_SETUP = pyenv-requirements-setup
GET_VIRTUALENV_PYTHON_VERSION = get-virtualenv-python-version
GENERATE_CODIUM_WORKSPACE_SETTINGS = generate-codium-workspace-settings

# executables
PIP = pip
POETRY = poetry
PYENV = pyenv
PYTHON = python
python_executables = \
	${PYENV}

# sane defaults
export PYTHON_VIRTUALENV_NAME = $(shell basename ${CURDIR})
PYTHON_REQUIREMENTS_FILE_PATH = ./requirements.txt

define GEN_WORKSPACE_SETTINGS_SCRIPT =
cat << _EOF_
# Standard Library Imports
import collections
import json

# Third Party Imports

# Local Application Imports


with open("${WORKSPACE_SETTINGS_CONFIG_PATH}", "r") as file_target:
	try:
		workspace_settings = json.load(file_target)
	except json.decoder.JSONDecodeError:
		# in the event the settings file is empty, or the json is invalid
		workspace_settings = json.loads("{}")

# inspired by:
# https://stackoverflow.com/questions/1024847/how-can-i-add-new-keys-to-a-dictionary#answer-1165836
workspace_settings.update(
	{
		"ansible.ansible.path": "${PYENV_VIRTUAL_ENV}/bin/ansible",
		"ansible.ansibleLint.enabled": True,
		"ansible.ansibleLint.path": "${PYENV_VIRTUAL_ENV}/bin/ansible-lint",
		"ansible.python.interpreterPath": "${PYENV_VIRTUAL_ENV}/bin/python",
	}
)
ordered_workspace_settings = collections.OrderedDict(
	workspace_settings.items()
)

with open("${WORKSPACE_SETTINGS_CONFIG_PATH}", "w") as file_target:
	json.dump(ordered_workspace_settings, file_target, indent=4)
	file_target.write("\n")

_EOF_
endef
export GEN_WORKSPACE_SETTINGS_SCRIPT

.PHONY: ${PRE_PYENV_SETUP}
${PRE_PYENV_SETUP}:
>	rm --force "./.python-version"

	# MONITOR(cavcrosby): 'pyenv uninstall' does not remove the underlying target,
	# hence this workaround is temporarily needed. For reference on the related GitHub
	# issue:
	# https://github.com/pyenv/pyenv-virtualenv/issues/436 
>	rm --recursive --force "$$(readlink ${PYENV_PREFIX_PATH})" \
>		&& ${PYENV} uninstall --force "${PYTHON_VIRTUALENV_NAME}"

.PHONY: ${PYENV_VIRTUALENV}
${PYENV_VIRTUALENV}:
>	@${PYENV} versions | grep --quiet '${VIRTUALENV_PYTHON_VERSION}' || { echo "make: python \"${VIRTUALENV_PYTHON_VERSION}\" is not installed by ${PYENV}"; exit 1; }
>	${PYENV} virtualenv --force "${VIRTUALENV_PYTHON_VERSION}" "${PYTHON_VIRTUALENV_NAME}"

	# mainly used to enter the virtualenv when in the dir
>	${PYENV} local "${PYTHON_VIRTUALENV_NAME}"

.PHONY: ${PYENV_POETRY_VIRTUALENV_SETUP}
${PYENV_POETRY_VIRTUALENV_SETUP}:
	# to ensure the most current versions of dependencies can be installed
>	${PYTHON} -m ${PIP} install --upgrade ${PIP}
>	${PYTHON} -m ${PIP} install ${POETRY}==1.1.7

	# MONITOR(cavcrosby): temporary workaround due to poetry now breaking on some
	# package installs. For reference:
	# https://stackoverflow.com/questions/69836936/poetry-attributeerror-link-object-has-no-attribute-name#answer-69987715
>	${PYTHON} -m ${PIP} install poetry-core==1.0.4
>	${PYENV} rehash

	# Needed to make sure poetry doesn't panic and create a virtualenv, redirecting
	# dependencies into the wrong virtualenv.
	#
	# TODO(cavcrosby): change to 'poetry config <key> <value> --local' format once
	# my repositories converge on localizing poetry configs to themselves.
>	${POETRY} config virtualenvs.create false

	# --no-root because we only want to install dependencies
>	${POETRY} install --no-root || { echo "make: ${POETRY} failed to install project dependencies"; exit 1; }
>	${PYENV} rehash

.PHONY: ${PYENV_REQUIREMENTS_VIRTUALENV_SETUP}
${PYENV_REQUIREMENTS_VIRTUALENV_SETUP}:
>	${PYTHON} -m ${PIP} install --upgrade ${PIP}
>	${PYTHON} -m ${PIP} install --requirement "${PYTHON_REQUIREMENTS_FILE_PATH}"

.PHONY: ${PYENV_POETRY_SETUP}
${PYENV_POETRY_SETUP}: PYENV_PREFIX_PATH := ${PYENV_ROOT}/versions/${PYTHON_VIRTUALENV_NAME}
${PYENV_POETRY_SETUP}: ${PRE_PYENV_SETUP} ${PYENV_VIRTUALENV}
	# If VIRTUALENV_PYTHON_VERSION is 'system', then PYENV_PREFIX_PATH will just be
	# a normal dir.
>	PYENV_VIRTUAL_ENV="$$(readlink ${PYENV_PREFIX_PATH} || echo ${PYENV_PREFIX_PATH})" \
		&& export PYENV_VIRTUAL_ENV \
		&& VIRTUAL_ENV="$$(readlink ${PYENV_PREFIX_PATH} || echo ${PYENV_PREFIX_PATH})" \
		&& export VIRTUAL_ENV \
		&& ${MAKE} ${PYENV_POETRY_VIRTUALENV_SETUP}

.PHONY: ${PYENV_REQUIREMENTS_SETUP}
${PYENV_REQUIREMENTS_SETUP}: PYENV_PREFIX_PATH := ${PYENV_ROOT}/versions/${PYTHON_VIRTUALENV_NAME}
${PYENV_REQUIREMENTS_SETUP}: ${PRE_PYENV_SETUP} ${PYENV_VIRTUALENV}
>	PYENV_VIRTUAL_ENV="$$(readlink ${PYENV_PREFIX_PATH} || echo ${PYENV_PREFIX_PATH})" \
		&& export PYENV_VIRTUAL_ENV \
		&& VIRTUAL_ENV="$$(readlink ${PYENV_PREFIX_PATH} || echo ${PYENV_PREFIX_PATH})" \
		&& export VIRTUAL_ENV \
		&& ${MAKE} ${PYENV_REQUIREMENTS_VIRTUALENV_SETUP}

.PHONY: ${GENERATE_CODIUM_WORKSPACE_SETTINGS}
${GENERATE_CODIUM_WORKSPACE_SETTINGS}: WORKSPACE_CONFIGS_PATH = ./.vscode
${GENERATE_CODIUM_WORKSPACE_SETTINGS}: WORKSPACE_SETTINGS_CONFIG_PATH = ${WORKSPACE_CONFIGS_PATH}/settings.json
${GENERATE_CODIUM_WORKSPACE_SETTINGS}: TEMP_PYSCRIPT := $(shell mktemp)
${GENERATE_CODIUM_WORKSPACE_SETTINGS}:
>	mkdir --parents "${WORKSPACE_CONFIGS_PATH}"
>   touch "${WORKSPACE_SETTINGS_CONFIG_PATH}"
>
>	eval "$${GEN_WORKSPACE_SETTINGS_SCRIPT}" > "${TEMP_PYSCRIPT}"
>	${PYTHON} "${TEMP_PYSCRIPT}"

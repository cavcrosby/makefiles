# recursive variables

# targets
PYENV_VIRTUALENV = pyenv-virtualenv
PYENV_POETRY_SETUP = pyenv-poetry-setup
PYENV_REQUIREMENTS_SETUP = pyenv-requirements-setup
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
VIRTUALENV_PYTHON_VERSION = 3.9.5
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
		# in the event the settings file is empty
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

.PHONY: ${PYENV_VIRTUALENV}
${PYENV_VIRTUALENV}:
>	@${PYENV} versions | grep --quiet '${VIRTUALENV_PYTHON_VERSION}' || { echo "make: python \"${VIRTUALENV_PYTHON_VERSION}\" is not installed by ${PYENV}"; exit 1; }
>	${PYENV} virtualenv --force "${VIRTUALENV_PYTHON_VERSION}" "${PYTHON_VIRTUALENV_NAME}"

	# mainly used to enter the virtualenv when in the dir
>	${PYENV} local "${PYTHON_VIRTUALENV_NAME}"

.PHONY: ${PYENV_POETRY_SETUP}
${PYENV_POETRY_SETUP}: ${PYENV_VIRTUALENV}
>	export PYENV_VERSION="${PYTHON_VIRTUALENV_NAME}"

	# to ensure the most current versions of dependencies can be installed
>	${PYTHON} -m ${PIP} install --upgrade ${PIP}
>	${PYTHON} -m ${PIP} install ${POETRY}==1.1.7

	# MONITOR(cavcrosby): temporary workaround due to poetry now breaking on some
	# package installs. For reference:
	# https://stackoverflow.com/questions/69836936/poetry-attributeerror-link-object-has-no-attribute-name#answer-69987715
>	${PYTHON} -m ${PIP} install poetry-core==1.0.4

	# Needed to make sure poetry doesn't panic and create a virtualenv, redirecting
	# dependencies into the wrong virtualenv.
>	${PYENV} exec ${POETRY} config virtualenvs.create false

	# --no-root because we only want to install dependencies. 'pyenv exec' is needed
	# as poetry is installed into a virtualenv bin dir that is not added to the
	# current shell PATH.
>	${PYENV} exec ${POETRY} install --no-root || { echo "make: ${POETRY} failed to install project dependencies"; exit 1; }
>	unset PYENV_VERSION

.PHONY: ${PYENV_REQUIREMENTS_SETUP}
${PYENV_REQUIREMENTS_SETUP}: ${PYENV_VIRTUALENV}
>	export PYENV_VERSION="${PYTHON_VIRTUALENV_NAME}"

>	${PYTHON} -m ${PIP} install --upgrade ${PIP}
>	${PYTHON} -m ${PIP} install --requirement "${PYTHON_REQUIREMENTS_FILE_PATH}"

>	unset PYENV_VERSION

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

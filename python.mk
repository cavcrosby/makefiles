# recursive variables

# targets
PYENV_VIRTUALENV = pyenv-virtualenv
PYENV_POETRY_SETUP = pyenv-poetry-setup
PYENV_REQUIREMENTS_SETUP = pyenv-requirements-setup

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
>	${PYENV} exec ${POETRY} install --no-root || { echo "${POETRY} failed to install project dependencies"; exit 1; }
>	unset PYENV_VERSION

.PHONY: ${PYENV_REQUIREMENTS_SETUP}
${PYENV_REQUIREMENTS_SETUP}: ${PYENV_VIRTUALENV}
>	export PYENV_VERSION="${PYTHON_VIRTUALENV_NAME}"

>	${PYTHON} -m ${PIP} install --upgrade ${PIP}
>	${PYTHON} -m ${PIP} install --requirement "${PYTHON_REQUIREMENTS_FILE_PATH}"

>	unset PYENV_VERSION

# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursively expanded variables
SHELL = /usr/bin/sh
TRUTHY_VALUES = \
    true\
    1

# gnu install directory variables
prefix = ${HOME}/.local
exec_prefix = ${prefix}
includedir = ${prefix}/include
bin_dir = ${exec_prefix}/bin

# targets
HELP = help
SETUP = setup
INSTALL = install
UNINSTALL = uninstall
TEST = test
CLEAN = clean
IMAGE = image
DEPLOY = deploy
DISMANTLE = dismantle
PUBLISH = publish

# executables
ENVSUBST = envsubst
GIT = git
base_executables = \
	${GIT}

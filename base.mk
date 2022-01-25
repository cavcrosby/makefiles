# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursive variables
SHELL = /usr/bin/sh

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
CLEAN = clean

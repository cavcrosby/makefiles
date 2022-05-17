# recursively expanded variables

# targets
BITWARDEN_SESSION_CHECK = bitwarden-session-check
BITWARDEN_GET_SSH_KEYS = bitwarden-get-ssh-keys
BITWARDEN_GET_TLS_CERTS = bitwarden-get-tls-certs

# executables
BW = bw
bw_executables = \
	${BW}

# sane defaults
BITWARDEN_SSH_KEYS_DIR_PATH = .
BITWARDEN_TLS_CERTS_DIR_PATH = .

# default ssh key pulled from homelab-cm
BITWARDEN_SSH_KEYS_ITEMID = 9493f9e9-82e0-458f-b609-ae20004f8227
BITWARDEN_SSH_KEYS = \
	id_rsa_ron.pub

# default tls cert pulled from homelab-cm
BITWARDEN_TLS_CERTS_ITEMID = 0857a42d-0d60-4ecc-8c43-ae200066a2b3
BITWARDEN_TLS_CERTS = \
	libera.pem

.PHONY: ${BITWARDEN_SESSION_CHECK}
${BITWARDEN_SESSION_CHECK}:
ifeq ($(findstring ${SKIP_BITWARDEN_SESSION_CHECK},${TRUTHY_VALUES}),)
>	@${BW} login --check > /dev/null 2>&1 || \
		{ \
			echo "make: login to bitwarden and export BW_SESSION before running this target"; \
			exit 1; \
		}
>	@${BW} unlock --check > /dev/null 2>&1 || \
		{ \
			echo "make: unlock bitwarden vault and export BW_SESSION before running this target"; \
			exit 1; \
		}
endif

.PHONY: ${BITWARDEN_GET_SSH_KEYS}
${BITWARDEN_GET_SSH_KEYS}: ${BITWARDEN_SESSION_CHECK}
ifeq ($(findstring ${SKIP_BITWARDEN_GET_SSH_KEYS},${TRUTHY_VALUES}),)
>	@for ssh_key in ${BITWARDEN_SSH_KEYS}; do \
>		echo ${BW} get attachment $${ssh_key} --itemid \"${BITWARDEN_SSH_KEYS_ITEMID}\" --output \"${BITWARDEN_SSH_KEYS_DIR_PATH}/$${ssh_key}\"; \
>		${BW} get attachment $${ssh_key} --itemid "${BITWARDEN_SSH_KEYS_ITEMID}" --output "${BITWARDEN_SSH_KEYS_DIR_PATH}/$${ssh_key}"; \
>	done
endif

.PHONY: ${BITWARDEN_GET_TLS_CERTS}
${BITWARDEN_GET_TLS_CERTS}: ${BITWARDEN_SESSION_CHECK}
ifeq ($(findstring ${SKIP_BITWARDEN_GET_TLS_CERTS},${TRUTHY_VALUES}),)
>	@for tls_cert in ${BITWARDEN_TLS_CERTS}; do \
>		echo ${BW} get attachment $${tls_cert} --itemid \"${BITWARDEN_TLS_CERTS_ITEMID}\" --output \"${BITWARDEN_TLS_CERTS_DIR_PATH}/$${tls_cert}\"; \
>		${BW} get attachment $${tls_cert} --itemid "${BITWARDEN_TLS_CERTS_ITEMID}" --output "${BITWARDEN_TLS_CERTS_DIR_PATH}/$${tls_cert}"; \
>	done
endif

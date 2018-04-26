#!/bin/bash

set -e

export PATH='/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'

source /var/tmp/helpers/default.sh

readonly VAULT_FILES='/var/tmp/vault'

[[ -d $VAULT_FILES ]] || mkdir -p "$VAULT_FILES"

# The version 0.10.0 is currently the recommended stable version.
if [[ -z $VAULT_VERSION ]]; then
    VAULT_VERSION='0.10.0'
fi

apt_get_update

apt-get --assume-yes install \
    unzip \
    jq

ARCHIVE_FILE="vault_${VAULT_VERSION}_$(detect_os)_$(detect_platform).zip"

wget -O "${VAULT_FILES}/${ARCHIVE_FILE}" \
        "https://releases.hashicorp.com/vault/${VAULT_VERSION}/${ARCHIVE_FILE}"

unzip -q "${VAULT_FILES}/${ARCHIVE_FILE}" \
      -d "$VAULT_FILES"

cp -f "${VAULT_FILES}/vault" \
      /usr/local/bin/vault

chown root: /usr/local/bin/vault
chmod 755 /usr/local/bin/vault

setcap 'cap_ipc_lock=+ep' \
       /usr/local/bin/vault

adduser \
    --quiet \
    --system \
    --group \
    --home /nonexistent \
    --no-create-home \
    --disabled-login \
    vault

mkdir -p /etc/vault \
         /etc/vault/conf.d \
         /var/log/vault

chown root: /etc/vault \
            /etc/vault/conf.d

chmod 755 /etc/vault \
          /etc/vault/conf.d

chown vault:adm /var/log/vault
chmod 2750 /var/log/vault

cp -f "${VAULT_FILES}/config.hcl" \
      "${VAULT_FILES}/config.hcl.tls" \
      /etc/vault/

chown root: /etc/vault/*.hcl
chmod 644 /etc/vault/*.hcl

cp -f "${VAULT_FILES}/vault.default" \
      /etc/default/vault

chown root: /etc/default/vault
chmod 644 /etc/default/vault

cp -f "${VAULT_FILES}/vault.logrotate" \
      /etc/logrotate.d/vault

chown root: /etc/logrotate.d/vault
chmod 644 /etc/logrotate.d/vault

cp -f "${VAULT_FILES}/vault.service" \
      /lib/systemd/system/vault.service

chown root: /lib/systemd/system/vault.service
chmod 644 /lib/systemd/system/vault.service

systemctl --system daemon-reload

for action in disable stop; do
    systemctl "$action" vault || true
done

cat <<'EOF' > /etc/bash_completion.d/vault
complete -C /usr/local/bin/vault vault
EOF

chown root: /etc/bash_completion.d/vault
chmod 644 /etc/bash_completion.d/vault

rm -Rf $VAULT_FILES
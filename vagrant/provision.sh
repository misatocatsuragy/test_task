#!/usr/bin/env bash

PAM_PACKAGE='libpam-ssh-agent-auth'

ANSIBLE_USER='ansible'
ANSIBLE_HOME_DIR='/home/ansible'
ANSIBLE_AUTHKEYS_FILE="${ANSIBLE_HOME_DIR}/.ssh/authorized_keys"
ANSIBLE_PUBKEY_FILE='/vagrant/keys/id_rsa.pub'

SUDO_PAM_KEY_FILE='/etc/security/authorized_keys'
SUDO_PAM_CON_FILE='/etc/pam.d/sudo'
SUDO_PAM_LINE="auth    sufficient   pam_ssh_agent_auth.so   file=${SUDO_PAM_KEY_FILE}"
SUDO_ENV_KEEP_LINE='Defaults env_keep += "SSH_AUTH_SOCK"'
SUDOERS_FILE='/etc/sudoers.d/ansible'

SSHD_CON_FILE='/etc/ssh/sshd_config'

echo "Prepare host management via ansible..."
echo "Install python"
apt-get update
apt-get install -y python3

echo "Install sudo and PAM ssh agent auth packages"
apt-get install -y sudo ${PAM_PACKAGE}

echo "Create ${SUDO_PAM_KEY_FILE}"
touch ${SUDO_PAM_KEY_FILE}
chmod 0600 ${SUDO_PAM_KEY_FILE}

echo "Change ${SUDO_PAM_CON_FILE} for ssh auth"
sed -i "/@include common-auth/i ${SUDO_PAM_LINE}" ${SUDO_PAM_CON_FILE}

echo "Create /etc/sudoers.d/ansible for ssh auth"
echo "${SUDO_ENV_KEEP_LINE}" >> ${SUDOERS_FILE}
chmod 0440 ${SUDOERS_FILE}

echo "Create ansible user"
useradd -c "Ansible user" -d ${ANSIBLE_HOME_DIR} -m \
-s /bin/sh ${ANSIBLE_USER}

echo "Copy public keys for ansible user"
mkdir ${ANSIBLE_HOME_DIR}/.ssh
touch ${ANSIBLE_AUTHKEYS_FILE}
chmod 0600 ${ANSIBLE_AUTHKEYS_FILE}
chown -R ${ANSIBLE_USER}: ${ANSIBLE_HOME_DIR}/.ssh

cat ${ANSIBLE_PUBKEY_FILE}  >> ${ANSIBLE_AUTHKEYS_FILE}
cat ${ANSIBLE_PUBKEY_FILE}  >> ${SUDO_PAM_KEY_FILE}

echo "Grant sudo privileges to ansible user"
echo "${ANSIBLE_USER} ALL=(ALL) ALL" >> ${SUDOERS_FILE}

echo "Enable ssh key auth"
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' ${SSHD_CON_FILE}
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' ${SSHD_CON_FILE}
systemctl restart sshd

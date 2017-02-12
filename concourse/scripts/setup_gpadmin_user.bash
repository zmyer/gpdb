#!/bin/bash

# Based on install_hawq_toolchain.bash in Pivotal-DataFabric/ci-infrastructure repo

set -euxo pipefail
setup_ssh_for_user() {
  local user="${1}"
  local home_dir
  home_dir=$(eval echo "~${user}")

  mkdir -p "${home_dir}"/.ssh
  touch "${home_dir}/.ssh/authorized_keys" "${home_dir}/.ssh/known_hosts" "${home_dir}/.ssh/config"
  ssh-keygen -t rsa -N "" -f "${home_dir}/.ssh/id_rsa"
  cat "${home_dir}/.ssh/id_rsa.pub" >> "${home_dir}/.ssh/authorized_keys"
  chmod 0600 "${home_dir}/.ssh/authorized_keys"
  cat << 'NOROAMING' >> "${home_dir}/.ssh/config"
Host *
  UseRoaming no
NOROAMING
  chown -R "${user}" "${home_dir}/.ssh"
}

ssh_keyscan_for_user() {
  local user="${1}"
  local home_dir
  home_dir=$(eval echo "~${user}")

  {
    ssh-keyscan localhost
    ssh-keyscan 0.0.0.0
    ssh-keyscan github.com
  } >> "${home_dir}/.ssh/known_hosts"
}

transfer_ownership() {
  chown -R gpadmin:gpadmin gpdb_src
  [ -d /usr/local/gpdb ] && chown -R gpadmin:gpadmin /usr/local/gpdb
  [ -d /usr/local/greenplum-db-devel ] && chown -R gpadmin:gpadmin /usr/local/greenplum-db-devel
  chown -R gpadmin:gpadmin /home/gpadmin
}

set_limits() {
  # Currently same as what's recommended in install guide
  if [ -d /etc/security/limits.d ]; then
    cat > /etc/security/limits.d/gpadmin-limits.conf <<-EOF
		gpadmin soft core unlimited
		gpadmin soft nproc 131072
		gpadmin soft nofile 65536
	EOF
  fi
  # Print now effective limits for gpadmin
  su gpadmin -c 'ulimit -a'
}

setup_gpadmin_user() {
  /usr/sbin/useradd gpadmin
  echo -e "password\npassword" | passwd gpadmin
  groupadd supergroup
  usermod -a -G supergroup gpadmin
  usermod -a -G tty gpadmin
  setup_ssh_for_user gpadmin
  transfer_ownership
  set_limits
}

setup_sshd() {
  test -e /etc/ssh/ssh_host_key || ssh-keygen -f /etc/ssh/ssh_host_key -N '' -t rsa1
  test -e /etc/ssh/ssh_host_rsa_key || ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
  test -e /etc/ssh/ssh_host_dsa_key || ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa

  # See https://gist.github.com/gasi/5691565
  sed -ri 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
  # Disable password authentication so builds never hang given bad keys
  sed -ri 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

  setup_ssh_for_user root

  # Test that sshd can start
  /etc/init.d/sshd start

  ssh_keyscan_for_user root
  ssh_keyscan_for_user gpadmin
}

_main() {
  setup_gpadmin_user
  setup_sshd
}

_main "$@"

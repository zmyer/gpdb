#!/bin/bash -l

set -exo pipefail

CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CWDIR}/common.bash"

function gen_env(){
	cat > /home/gpadmin/run_regression_test.sh <<-EOF
	set -exo pipefail

	source /opt/gcc_env.sh
	source /usr/local/greenplum-db-devel/greenplum_path.sh

	cd "\${1}/gpdb_src/gpAux"
	source gpdemo/gpdemo-env.sh

	wget -P /tmp http://www-us.apache.org/dist/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz
	tar zxf /tmp/hadoop-2.7.3.tar.gz -C /tmp
	export HADOOP_HOME=/tmp/hadoop-2.7.3

	cat > "\${HADOOP_HOME}/etc/hadoop/core-site.xml" <<-EOFF
		<configuration>
		<property>
		<name>fs.defaultFS</name>
		<value>hdfs://localhost:9000/</value>
		</property>
		</configuration>
	EOFF

	\${HADOOP_HOME}/bin/hdfs namenode -format -force
	\${HADOOP_HOME}/sbin/start-dfs.sh

	cd "\${1}/gpdb_src/gpAux/extensions/gphdfs/regression/integrate"
	HADOOP_HOST=localhost HADOOP_PORT=9000 ./generate_gphdfs_data.sh

	cd "\${1}/gpdb_src/gpAux/extensions/gphdfs/regression"
	GP_HADOOP_TARGET_VERSION=cdh4.1 HADOOP_HOST=localhost HADOOP_PORT=9000 ./run_gphdfs_regression.sh

	[ -s regression.diffs ] && cat regression.diffs && exit 1
	exit 0
	EOF

	chown -R gpadmin:gpadmin $(pwd)
	chown gpadmin:gpadmin /home/gpadmin/run_regression_test.sh
	chmod a+x /home/gpadmin/run_regression_test.sh
}

function run_regression_test() {
	su - gpadmin -c "bash /home/gpadmin/run_regression_test.sh $(pwd)"
}

function setup_gpadmin_user() {
	./gpdb_src/concourse/scripts/setup_gpadmin_user.bash "$TARGET_OS"
}

function _main() {
	if [ -z "$TARGET_OS" ]; then
		echo "FATAL: TARGET_OS is not set"
		exit 1
	fi

	if [ "$TARGET_OS" != "centos" -a "$TARGET_OS" != "sles" ]; then
		echo "FATAL: TARGET_OS is set to an invalid value: $TARGET_OS"
		echo "Configure TARGET_OS to be centos or sles"
		exit 1
	fi

	time configure
	sed -i s/1024/unlimited/ /etc/security/limits.d/90-nproc.conf
	time install_gpdb
	time setup_gpadmin_user
	time make_cluster
	time gen_env

	time run_regression_test
}

_main "$@"

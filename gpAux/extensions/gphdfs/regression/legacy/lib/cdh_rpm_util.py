"""
Copyright (C) 2004-2015 Pivotal Software, Inc. All rights reserved.

This program and the accompanying materials are made available under
the terms of the under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

import os
import re
import tinctest

from rpm_util import RPMUtil
from tinctest.lib import local_path, run_shell_command

from hadoop_util import HadoopUtil

class CDHRpmUtil(HadoopUtil):
    """Utility for installing PHD Single node clusters using RPMs"""
    
    def __init__(
                    self, hadoop_artifact_url, hadoop_install_dir, hadoop_data_dir, template_conf_dir, hostname = 'localhost',
                    secure_hadoop = False
                ):
        HadoopUtil.__init__(self, hadoop_artifact_url, hadoop_install_dir, hadoop_data_dir,  hostname)
        self.rpmutil = RPMUtil()
        self.hostname = hostname
        self.hadoop_artifact_url = hadoop_artifact_url
        self.hadoop_install_dir = hadoop_install_dir
        self.hadoop_binary_loc = ''
        self.hadoop_data_dir = hadoop_data_dir
        self.template_conf_dir = local_path(template_conf_dir)
        self.secure_hadoop = secure_hadoop
        # Constants
        # under the hadoop template configuration directory
        # both the below directories should be present
        self.SECURE_DIR_NAME = "conf.secure"        # secure configuration files location   
        self.NON_SECURE_DIR_NAME = "conf.pseudo"    # non-secure configuration files location
        self.DEPENDENCY_PKGS = [
                                    "fuse-",        # eg. fuse-2.8.3-4.el6.x86_64 
                                    "fuse-libs",    # eg. fuse-libs-2.8.3-4.el6.x86_6
                                    "nc-"           # eg. 1.84-22.el6.x86_64"
                                ]
        self.PKGS_TO_REMOVE = "^hadoop-*|^bigtop-*|^zookeeper-*|^parquet-*"
        self.HADOOP_ENVS = {
                                "HADOOP_HOME" : "/usr/lib/hadoop/",
                                "HADOOP_COMMON_HOME" : "/usr/lib/hadoop/",
                                "HADOOP_HDFS_HOME" : "/usr/lib/hadoop-hdfs/",
                                "HADOOP_MAPRED_HOME" : "/usr/lib/hadoop-mapreduce/",
                                "YARN_HOME" : "/usr/lib/hadoop-yarn/",
                                "HADOOP_TMP_DIR" : "%s/hadoop-hdfs/cache/" %self.hadoop_data_dir,
                                "MAPRED_TMP_DIR" : "%s/hadoop-mapreduce/cache/" %self.hadoop_data_dir,
                                "YARN_TMP_DIR" : "%s/hadoop-yarn/cache/" %self.hadoop_data_dir,
                                "HADOOP_CONF_DIR" : "/etc/hadoop/conf",
                                "HADOOP_LOG_DIR" : "%s/hadoop-logs/hadoop-hdfs" %self.hadoop_data_dir,
                                "MAPRED_LOG_DIR" : "%s/hadoop-logs/hadoop-mapreduce" %self.hadoop_data_dir,
                                "YARN_LOG_DIR" : "%s/hadoop-logs/hadoop-yarn" %self.hadoop_data_dir 
                            }
        
        
    def _remove_installed_pkgs(self):
        self.rpmutil.erase_all_packages(self.PKGS_TO_REMOVE)
    
    def _install_dependency_pkgs(self):
        for pkg in self.DEPENDENCY_PKGS:
            if not self.rpmutil.is_pkg_installed("^" + pkg):
                self.rpmutil.install_package_using_yum(pkg, is_regex_pkg_name = True)
                
    def cleanup(self):
        """
        Clean-up process to:
        1. kill all the hadoop daemon process from previous runs if any
        2. Remove the contents from the hadoop installation & configuration locations
        """
        self.stop_hadoop()
        cmd_str = "ps aux | awk '/\-Dhadoop/{print $2}' | xargs sudo kill -9"
        run_shell_command(cmd_str, "Kill zombie hadoop daemons")
        cmd_str = "sudo rm -rf "
        for key,value in self.HADOOP_ENVS.iteritems():
            cmd_str = cmd_str + value +"* "
        cmd_str = cmd_str + "/etc/gphd"
        run_shell_command(cmd_str,"Clean up HDFS files")
        self._remove_installed_pkgs()
        
    def download_binary(self):
        """
        1. Downloads the hadoop binary
        2. Untars the binary into the specified installation location
        """
        # check if the installation exists or not
        # delete its contents if exist else create a new one
        if os.path.isdir(self.hadoop_install_dir):
            cmd_str = "sudo rm -rf %s/*" %self.hadoop_install_dir
        else:
            cmd_str = "mkdir -p %s" %self.hadoop_install_dir
        run_shell_command(cmd_str,"Check Hadoop install directory")
        res = {'rc':0, 'stdout':'', 'stderr':''}
        run_shell_command("basename %s" %self.hadoop_artifact_url, "To get binary name", res)
        binary_name = res['stdout'].split('\n')[0]
        tinctest.logger.debug("Hadoop Binary - %s" %binary_name)
        binary_path = os.path.join(self.hadoop_install_dir, binary_name)
        tinctest.logger.debug("Hadoop Binary Path - %s" %binary_path)
        cmd_str = "wget -O %s %s" %(binary_path, self.hadoop_artifact_url)
        res = {}
        result = run_shell_command(cmd_str, "Download binary", res)
        if not result:
            raise Exception("Failed to download hadoop binary: %s" %res['stderr'])
        res = {}
        cmd_str = "sudo yum --nogpgcheck localinstall %s -y" %binary_path
        result = run_shell_command(cmd_str, "Extract binary", res)
        if not result:
            raise Exception("Failed to extract hadoop binary: %s" %res['stderr'])
    
    def install_binary(self):
        """
        Installs RPM binaries of:
        1. utility  eg. bigtop utils
        2. zookeeper
        3. hadoop 
        """
        
        binaries_list = [
                            "zookeeper", "hadoop-hdfs-namenode", "hadoop-hdfs-secondarynamenode", \
                            "hadoop-hdfs-datanode", "hadoop-yarn-resourcemanager", "hadoop-mapreduce", \
                            "hadoop-yarn-nodemanager", "hadoop-mapreduce-historyserver", \
                            "hadoop-yarn-proxyserver"
                        ]
        yum_cmd = "sudo yum clean all; sudo yum install -y "
        for binary in binaries_list:
            res = {}
            cmd_str = yum_cmd + binary
            if not run_shell_command(cmd_str, "Installing %s" %binary, res):
                raise Exception("Failed to install %s : %s" %(binary, res['stderr']))

    def install_hadoop_configurations(self):
        """
        Based on type of installation secure or non-secure, 
        installs the updated template configuration files
        and makes required changes to the env files.
        """
        ##TODO: Create separate directories for secure & non-secure
        ## in the hadoop conf dir and copy the update configs in respective directories
        # check the type of hadoop installation - secure or non secure
        if self.secure_hadoop:
            # SECURE_DIR_NAME is expected to be present under template configuration directory
            secure_conf = os.path.join(self.template_conf_dir, self.SECURE_DIR_NAME)
            super(CDHRpmUtil,self).install_hadoop_configurations(secure_conf, self.HADOOP_ENVS['HADOOP_CONF_DIR'])
            # update env files in /etc/default/hadoop*
            if self.hadoop_data_dir.endswith('/'):
                self.hadoop_data_dir = self.hadoop_data_dir[:-1]
            cmd_str =   "for env_file in `ls /etc/default/hadoop*`;"  \
                        "do "   \
                        "sudo sed -r -i 's:\/var\/log(\/gphd)?:\%s\/hadoop-logs:g' ${env_file};" \
                        "done" %self.hadoop_data_dir
            run_shell_command(cmd_str, "Update env files in /etc/default/hadoop*")
             
            # update hadoop-env.sh file
            hadoop_env_file = os.path.join( self.HADOOP_ENVS['HADOOP_CONF_DIR'], "hadoop-env.sh" )
            if not os.path.exists(hadoop_env_file):
                tinctest.logger.info("hadoop-env.sh not found..creating a new one!") 
                run_shell_command("sudo touch %s" %hadoop_env_file, "Create hadoop-env.sh file")
            # give write permissions on the file 
            self.give_others_write_perm(hadoop_env_file)
            text =  "\n### Added env variables\n" \
                    "export JAVA_HOME=%s\n" \
                    "export HADOOP_OPTS=\"-Djava.net.preferIPv4Stack=true " \
                    "-Djava.library.path=$HADOOP_HOME/lib/native/\"\n" %self.get_java_home()
            self.append_text_to_file(hadoop_env_file,text)
            # revert back to old permissions
            self.remove_others_write_perm(hadoop_env_file)
            # update env files hadoop-hdfs-datanode & hadoop
            hdfs_datanode_env = "/etc/default/hadoop-hdfs-datanode"
            self.give_others_write_perm(hdfs_datanode_env)
            text =  "\n### Secure env variables\n" \
                    "export HADOOP_SECURE_DN_USER=hdfs\n"  \
                    "export HADOOP_SECURE_DN_LOG_DIR=${HADOOP_LOG_DIR}/hdfs\n" \
                    "export HADOOP_PID_DIR=/var/run/hadoop-hdfs/\n"    \
                    "export HADOOP_SECURE_DN_PID_DIR=${HADOOP_PID_DIR}\n"   \
                    "export JSVC_HOME=/usr/libexec/bigtop-utils\n"
                    
            self.append_text_to_file(hdfs_datanode_env, text)
            self.remove_others_write_perm(hdfs_datanode_env)
            
            # change the permissions of container-executor
            container_bin_path = os.path.join(self.HADOOP_ENVS['YARN_HOME'],'bin/container-executor')
            cmd_str = "sudo chown root:yarn %s" %container_bin_path
            run_shell_command(cmd_str)
            cmd_str = "sudo chmod 050 %s" %container_bin_path
            run_shell_command(cmd_str)
            cmd_str = "sudo chmod u+s %s" %container_bin_path
            run_shell_command(cmd_str)
            cmd_str = "sudo chmod g+s %s" %container_bin_path
            run_shell_command(cmd_str) 
        else:
            # NON_SECURE_DIR_NAME is expected to be present under template configuration directory
            non_secure_conf = os.path.join(self.template_conf_dir, self.NON_SECURE_DIR_NAME)
            super(CDHRpmUtil, self).install_hadoop_configurations(non_secure_conf, self.HADOOP_ENVS['HADOOP_CONF_DIR'])
            
    def start_hdfs(self):
        # format namenode
        cmd_str = "sudo -u hdfs hdfs --config %s namenode -format" %self.HADOOP_ENVS['HADOOP_CONF_DIR']
        namenode_formatted = run_shell_command(cmd_str)
        if not namenode_formatted:
            raise Exception("Exception in namnode formatting")
        
        # start namenode
        cmd_str = "sudo /etc/init.d/hadoop-hdfs-namenode start"
        namenode_started = run_shell_command(cmd_str)
        if not namenode_started:
            raise Exception("Namenode not started")
        
        
        cmd_str = "sudo /etc/init.d/hadoop-hdfs-datanode start"
        namenode_started = run_shell_command(cmd_str)
        if not namenode_started:
            raise Exception("Namenode not started")
            
        cmd_str = "sudo /etc/init.d/hadoop-hdfs-secondarynamenode start"
        namenode_started = run_shell_command(cmd_str)
        if not namenode_started:
            raise Exception("Secondary namenode not started")

    def set_hdfs_permissions(self):
        if self.secure_hadoop:
            hdfs_cmd = "sudo hdfs dfs"
        else:
            hdfs_cmd = "sudo -u hdfs hdfs dfs"
        # set hdfs permissions
        cmd_str = "%s -chmod -R 777 /" %hdfs_cmd
        run_shell_command(cmd_str)
        cmd_str = "%s -mkdir /tmp" %hdfs_cmd
        run_shell_command(cmd_str)
        cmd_str = "%s -chmod 777 /tmp" %hdfs_cmd
        run_shell_command(cmd_str)
        cmd_str = "%s -mkdir -p /var/log/hadoop-yarn" %hdfs_cmd
        run_shell_command(cmd_str)
        cmd_str = "%s -mkdir -p /user" %hdfs_cmd
        run_shell_command(cmd_str)
        cmd_str = "%s -mkdir -p /user/history" %hdfs_cmd
        run_shell_command(cmd_str)
        cmd_str = "%s -chmod -R 1777 /user/history" %hdfs_cmd
        run_shell_command(cmd_str)
        cmd_str = "%s -chmod -R 777 /user/" %hdfs_cmd
        run_shell_command(cmd_str)

    def put_file_in_hdfs(self, input_path, hdfs_path):
        if hdfs_path.rfind('/') > 0:
            hdfs_dir = hdfs_path[:hdfs_path.rfind('/')]
            cmd_str = "hdfs dfs -mkdir -p %s" %hdfs_dir
            run_shell_command(cmd_str, "Creating parent HDFS dir for path %s" %input_path)
        cmd_str = "hdfs dfs -put %s %s" %(input_path, hdfs_path)
        run_shell_command(cmd_str, "Copy to HDFS : file %s" %input_path)
            
    def remove_file_from_hdfs(self, hdfs_path):
        cmd_str = "hdfs dfs -rm -r %s" %hdfs_path
        run_shell_command(cmd_str, "Remove %s from HDFS" %hdfs_path)

         
    def start_yarn(self):
        # start yarn daemons
        # start resource manager
        self.set_hdfs_permissions()
        cmd_str = "sudo /etc/init.d/hadoop-yarn-resourcemanager start"
        namenode_started = run_shell_command(cmd_str)
        if not namenode_started:
            raise Exception("Resource manager not started")
        
        # start node manager
        cmd_str = "sudo /etc/init.d/hadoop-yarn-nodemanager start"
        namenode_started = run_shell_command(cmd_str)
        if not namenode_started:
            raise Exception("Node manager not started")
        
        # start history server
        cmd_str = "sudo /etc/init.d/hadoop-mapreduce-historyserver start"
        namenode_started = run_shell_command(cmd_str)
        if not namenode_started:
            raise Exception("History server not started")
            
            
    def start_hadoop(self):
        """
        Starts the PHD cluster and checks the JPS status
        """
        self.start_hdfs()
        self.start_yarn()
        res = {}
        # run jps command & check for hadoop daemons
        cmd_str = "sudo jps"
        run_shell_command(cmd_str, "Check Hadoop Daemons", res)
        result = res['stdout']
        tinctest.logger.info("\n**** Following Hadoop Daemons started **** \n%s" %result)
        tinctest.logger.info("*** Hadoop Started Successfully!!")
        
    def stop_hadoop(self):
        """
        Stops the PHD cluster
        """
        run_shell_command("sudo /etc/init.d/hadoop-mapreduce-historyserver stop", "Stop history-server")
        run_shell_command("sudo /etc/init.d/hadoop-yarn-nodemanager stop", "Stop Node manager")
        run_shell_command("sudo /etc/init.d/hadoop-yarn-resourcemanager stop", "Stop resourcemanager")
        run_shell_command("sudo /etc/init.d/hadoop-hdfs-secondarynamenode stop", "Stop secondarynamenode")
        run_shell_command("sudo /etc/init.d/hadoop-hdfs-datanode stop", "Stop datanode")
        run_shell_command("sudo /etc/init.d/hadoop-hdfs-namenode stop", "Stop namenode")

    def get_hadoop_env(self):
        """
        Returns a dictionary of hadoop environment variables like:
        1. HADOOP_HOME
        2. HADOOP_CONF_DIR
        3. HADOOP_COMMON_HOME
        4. HADOOP_HDFS_HOME
        5. YARN_HOME
        6. HADOOP_MAPRED_HOME
        """
        return self.HADOOP_ENVS
        
        
    def init_cluster(self):
        """
        Init point for starting up the PHD cluster
        """
        self.download_binary()
        self.cleanup()
        self.install_binary()
        self.install_hadoop_configurations()
        self.start_hadoop()
        

if __name__ == '__main__':
    hdfs_util = CDHRpmUtil("http://archive.cloudera.com/cdh4/one-click-install/redhat/6/x86_64/cloudera-cdh-4-0.x86_64.rpm","/data/gpadmin/hadoop_test","../configs/hdfs/cdh","localhost")
    hdfs_util.init_cluster()

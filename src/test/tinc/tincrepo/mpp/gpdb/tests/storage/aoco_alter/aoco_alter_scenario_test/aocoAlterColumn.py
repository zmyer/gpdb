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
import sys
import glob
from time import sleep
import time
import datetime
import tinctest
from tinctest.lib import local_path, Gpdiff
from mpp.lib.PSQL import PSQL
from gppylib.commands.base import Command
from mpp.models import MPPTestCase
from mpp.lib.gpConfig import GpConfig
from mpp.lib.gprecoverseg import GpRecover
from mpp.gpdb.tests.storage.lib.dbstate import DbStateClass
from mpp.lib.filerep_util import Filerepe2e_Util


class AOCOAlterColumn(MPPTestCase):
    
    def __init__(self):
        self.fileutil = Filerepe2e_Util()
        self.gprecover = GpRecover()
        self.config = GpConfig()
        self.base_dir = os.path.dirname(sys.modules[self.__class__.__module__].__file__)


    def get_sql_files(self, sql_file_name):
        sql_file = os.path.join( self.base_dir, "sql", sql_file_name + ".sql");    
        return  sql_file

    def validate_sql(self, ans_file, out_file):
        ''' Compare the out and ans files '''
        init_file=os.path.join( self.base_dir, "sql",'init_file')
        result1 = Gpdiff.are_files_equal(out_file, ans_file, match_sub =[init_file])
        self.assertTrue(result1 ,'Gpdiff.are_files_equal')        

    def run_sql(self, filename, out_file,background=False):
        ''' Run the provided sql and validate it '''
        out_file = local_path(filename.replace(".sql", ".out"))
        PSQL.run_sql_file(filename,out_file=out_file,background=background)


    def run_test_CatalogCheck(self, action,storage):
        file_name =action+'_'+storage
        sql_file = self.get_sql_files(file_name)
        out_file = self.base_dir+ "/sql/"+file_name+'.out'
        tinctest.logger.info( 'sql-file == %s \n' % sql_file)
        tinctest.logger.info( 'out-file == %s \n' % out_file)
        # Run Add/Drop Column script
        self.run_sql(sql_file, out_file=out_file)

    def validate_test_CatalogCheck(self, action,storage):
        file_name =action+'_'+storage
        out_file = self.base_dir+ "/sql/"+file_name+'.out'
        ans_file = self.base_dir+ "/expected/"+file_name+'.ans'
        tinctest.logger.info( 'out-file == %s \n' % out_file)
        tinctest.logger.info( 'ans-file == %s \n' % ans_file)
        # Validate Ans file
        self.validate_sql(ans_file,out_file)
        if storage == 'multisegfiles':
            ''' check if multi_segfile_tab file has  multiple segfiles per column '''
            tablename='multi_segfile_tab'
            relid = self.get_relid(file_name=tablename )
            utilitymodeinfo=self.get_utilitymode_conn_info( relid=relid)
            u_port=utilitymodeinfo[0]
            u_host=utilitymodeinfo[1]
            assert(1 < int(self.get_segment_cnt(relid=relid,host=u_host,port= u_port)))
        # Check Correctness of the catalog
        self.dbstate = DbStateClass('run_validation')
        outfile = local_path("gpcheckcat_"+datetime.datetime.fromtimestamp(time.time()).strftime('%Y%m%d%H%M%S')+".out")
        self.dbstate.check_catalog(outputFile=outfile)

    def run_test_ChangeTracking(self,filename):
        # Log the segment state before starting the test
        # Expectation is a SYNC state
        self.log_segment_state()
        primary_dbid=self.get_dbid()
        # Run the 'alter table add column cmmand' in the background
        self.run_sql_ChangeTracking(filename,stage='fail',validate=False,background=True)
        # Inject Fault to put one primary in panic
        self.fileutil.inject_fault(f='postmaster', y='reset',  seg_id=primary_dbid)
        self.fileutil.inject_fault(f='postmaster', y='panic',  seg_id=primary_dbid)
        state=self.fileutil.check_fault_status(fault_name='postmaster', status='triggered')
        self.log_segment_state()
        # Recover the down segments
        self.recover_seg()
        self.log_segment_state()
        # Validate that the previous alter failed because primary segment went down as the alter was taking place
        self.run_sql_ChangeTracking(filename,stage='failvalidate',validate=True,background=False) 
        # Now the system is in change tracking so the next alter should pass
        self.run_sql_ChangeTracking(filename,stage='pass',validate=True,background=False) 
        self.log_segment_state()


    def recover_seg(self):
        result=self.get_segcount_state(state='d')
        if result > 0:
            if not self.gprecover.incremental():
                raise Exception('Gprecoverseg failed')
            if not self.gprecover.wait_till_insync_transition():
                raise Exception('Segments not in sync')
        tinctest.logger.info('Segments recovered and back in sync')
        

    def run_sql_ChangeTracking(self,filename,stage,validate=False,background=False):
        fname=filename+'-'+stage
        sql_file = self.get_sql_files(fname)
        out_file = self.base_dir+ "/sql/"+fname +'.out'
        ans_file = self.base_dir+ "/expected/"+fname+'.ans'
        tinctest.logger.info( '\n==============stage = %s ================' % (stage))
        tinctest.logger.info( sql_file)
        tinctest.logger.info( out_file)
        tinctest.logger.info( ans_file)
        tinctest.logger.info( '==============================')
        result=self.run_sql(sql_file,out_file=out_file,background=background)
        if validate == True:
           self.validate_sql(ans_file,out_file)

 
    def get_dbid(self):
        sql_cmd = "select min(dbid) dbid from gp_segment_configuration where role = 'p' and status = 'u' and content > -1"
        dbid=PSQL.run_sql_command(sql_cmd= sql_cmd,flags='-q -t')
        tinctest.logger.info('Segments %s chosen for fault injection' % (dbid))
        return dbid
     
    def log_segment_state(self):
        sql_cmd = "select * from gp_segment_configuration order by dbid"
        result=PSQL.run_sql_command(sql_cmd= sql_cmd)
        tinctest.logger.info('==========================')
        tinctest.logger.info('State of Segments ')
        tinctest.logger.info(result)
        tinctest.logger.info('==========================')

    def get_segcount_state(self,state):
        sql_cmd = "select count(*) from gp_segment_configuration where status = '%s'" % (state)
        result=PSQL.run_sql_command(sql_cmd= sql_cmd,flags='-q -t')
        tinctest.logger.info('Number of segments in %s State == %d' % (state,(int(result))))
        return int(result)

    def get_utilitymode_conn_info(self, relid=0):
        #get the segment_id where to log in utility mode and then get the hostname and port for this segment
        sql_cmd="select port, hostname from gp_segment_configuration sc  where dbid > 1 and role = 'p' limit 1;"
        utilitymodeinfo=PSQL.run_sql_command(sql_cmd=sql_cmd,  flags='-q -t')
        u_port=utilitymodeinfo.strip().split('|')[0]
        u_host=utilitymodeinfo.strip().split('|')[1]
        return [u_port,u_host]

    def get_relid(self,file_name=None):
        sql_cmd="SELECT oid FROM pg_class WHERE relname='%s';\n" % file_name
        relid= PSQL.run_sql_command(sql_cmd=sql_cmd,  flags='-q -t')
        return relid;

    def get_segment_cnt(self, relid=0,host=None,port=None):
        sql_cmd="select count(*) from gp_toolkit.__gp_aocsseg(%s) group by column_num having count(*) > 1 limit 1" % (relid)
        segcnt=PSQL.run_sql_command_utility_mode(sql_cmd=sql_cmd,host=host, port=port,flags='-q -t')
        if (len(segcnt.strip()) == 0):
            segcnt='0'
        return segcnt

    def run_test_utility_mode(self,filename):
        #alter_aoco_tab_utilitymode
        relid = self.get_relid(file_name=filename )
        utilitymodeinfo=self.get_utilitymode_conn_info( relid=relid)
        u_port=utilitymodeinfo[0]
        u_host=utilitymodeinfo[1]
        self.run_sql_utility_mode(filename,host=u_host,port=u_port)

    
    def run_sql_utility_mode(self,filename,host=None,port=None):
        fname=filename
        sql_file = self.get_sql_files(fname)
        out_file = self.base_dir+ "/sql/"+fname +'.out'
        ans_file = self.base_dir+ "/expected/"+fname+'.ans'
        tinctest.logger.info( '\n==============================')
        tinctest.logger.info( sql_file)
        tinctest.logger.info( out_file)
        tinctest.logger.info( ans_file)
        tinctest.logger.info( '==============================')
        result=PSQL.run_sql_file_utility_mode(sql_file,out_file=out_file,host=host, port=port)
        self.validate_sql(ans_file,out_file)


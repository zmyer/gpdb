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
import tinctest

from tinctest.lib import local_path
from mpp.lib.config import GPDBConfig
from mpp.models import MPPTestCase
from mpp.lib.PSQL import PSQL
from gppylib.db import dbconn
from gppylib.commands.base import Command, ExecutionError
from tinctest.lib import Gpdiff

class AppendOnlyReadCheckTests(MPPTestCase):
    """
    @product_version gpdb: [4.3.5.0-]
    """
    def __init__(self, methodName):
        super(AppendOnlyReadCheckTests, self).__init__(methodName)
        self.base_dir = os.path.dirname(sys.modules[self.__module__].__file__)

        #Create the output directory
        self.output_dir = os.path.join(self.base_dir, 'output')
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)

        self.sql_dir = os.path.join(self.base_dir, 'sql')
        self.ans_dir = os.path.join(self.base_dir, 'expected')

    def create_appendonly_tables(self, row=True):
        sql_file_name = 'create_ao_table' if row else 'create_co_table'
        sql_file = os.path.join(self.sql_dir, '%s.sql' % sql_file_name)
        out_file = os.path.join(self.output_dir, '%s.out' % sql_file_name)
        ans_file = os.path.join(self.ans_dir, '%s.ans' % sql_file_name)
        PSQL.run_sql_file(sql_file, out_file=out_file)
        if not Gpdiff.are_files_equal(out_file, ans_file):
            raise Exception('Unable to create tables')

    def get_relfilenode_oid(self, tablename):
        RELFILENODE_OID_QUERY = """ SELECT relfilenode
                                    FROM pg_class
                                    WHERE relname='%s'
                                """ % tablename
        with dbconn.connect(dbconn.DbURL()) as conn:
            relfilenode_oid = dbconn.execSQLForSingleton(conn, RELFILENODE_OID_QUERY)
        return relfilenode_oid

    def transform_sql_file(self, sql_file, tablename):
        relfilenode_oid = self.get_relfilenode_oid(tablename)
        new_sql_file = sql_file.strip('.t')
        with open(new_sql_file, 'w') as fp1:
            with open(sql_file, 'r') as fp2:
                for line in fp2:
                    if '<relfilenode_oid>' in line:
                        line = line.replace('<relfilenode_oid>', str(relfilenode_oid))
                    fp1.write(line)

    def test_alter_appendonly(self):
        out_file = os.path.join(self.output_dir, 'alter_ao_co.out')
        ans_file = os.path.join(self.ans_dir, 'alter_ao_co.ans')
        sql_file = os.path.join(self.sql_dir, 'alter_ao_co.sql')
        PSQL.run_sql_file(sql_file, out_file=out_file)
        if not Gpdiff.are_files_equal(out_file, ans_file):
            raise Exception('Alter table failed for append only tables !')

    def test_vacuum_appendonly(self):
        out_file = os.path.join(self.output_dir, 'vacuum_ao_co.out')
        ans_file = os.path.join(self.ans_dir, 'vacuum_ao_co.ans')
        sql_file = os.path.join(self.sql_dir, 'vacuum_ao_co.sql')
        PSQL.run_sql_file(sql_file, out_file=out_file)
        if not Gpdiff.are_files_equal(out_file, ans_file):
            raise Exception('Vacuum table failed for append only tables !')

    def test_pg_aoseg_corruption(self):
        self.create_appendonly_tables()
        config = GPDBConfig()
        host, port = config.get_hostandport_of_segment() 
        self.transform_sql_file(os.path.join(self.sql_dir, 'corrupt_pg_aoseg.sql.t'), 'ao1')
        out_file = os.path.join(self.output_dir, 'corrupt_pg_aoseg.out')
        ans_file = os.path.join(self.ans_dir, 'corrupt_pg_aoseg.ans')
        sql_file = os.path.join(self.sql_dir, 'corrupt_pg_aoseg.sql')
        PSQL.run_sql_file_utility_mode(sql_file, out_file=out_file, host=host,
                          port=port, dbname=os.environ['PGDATABASE'])
        if not Gpdiff.are_files_equal(out_file, ans_file, match_sub=[local_path('sql/init_file')]):
            raise Exception('Corruption test of pg_aoseg failed for appendonly tables !')

    def test_pg_aocsseg_corruption(self):
        self.create_appendonly_tables(row=False)
        config = GPDBConfig()
        host, port = config.get_hostandport_of_segment() 
        self.transform_sql_file(os.path.join(self.sql_dir, 'corrupt_pg_aocsseg.sql.t'), 'co1')
        out_file = os.path.join(self.output_dir, 'corrupt_pg_aocsseg.out')
        ans_file = os.path.join(self.ans_dir, 'corrupt_pg_aocsseg.ans')
        sql_file = os.path.join(self.sql_dir, 'corrupt_pg_aocsseg.sql')
        PSQL.run_sql_file_utility_mode(sql_file, out_file=out_file, host=host,
                                       port=port, dbname=os.environ['PGDATABASE'])
        if not Gpdiff.are_files_equal(out_file, ans_file, match_sub=[local_path('sql/init_file')]):
            raise Exception('Corruption test of pg_aocsseg failed for appendonly tables !')

    def test_ao_read_check_subtransaction(self):
        sql_file = os.path.join(self.sql_dir, 'sub_transaction.sql') 
        ans_file = os.path.join(self.ans_dir, 'sub_transaction.ans') 
        out_file = os.path.join(self.output_dir, 'sub_transaction.out')
        PSQL.run_sql_file(sql_file=sql_file, out_file=out_file)
        if not Gpdiff.are_files_equal(out_file, ans_file):
            raise Exception('Subtransaction tests failed !')


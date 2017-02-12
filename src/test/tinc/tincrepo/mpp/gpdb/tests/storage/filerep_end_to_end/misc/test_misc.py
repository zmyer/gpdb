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

from mpp.models import SQLTestCase

class PrimarySyncTestCase(SQLTestCase):
    """
    @gucs gp_create_table_random_default_distribution=off
    """

    sql_dir = 'PrimarySync/sql/'
    ans_dir = 'PrimarySync/expected/'
    out_dir = 'PrimarySync/output/'

class MirrorCTTestCase(SQLTestCase):
    """
    @gucs gp_create_table_random_default_distribution=off
    """

    sql_dir = 'MirrorCT/sql/'
    ans_dir = 'MirrorCT/expected/'
    out_dir = 'MirrorCT/output/'

class RolesSwappedTestCase(SQLTestCase):
    """
    @gucs gp_create_table_random_default_distribution=off
    """
    sql_dir = 'RolesSwapped/sql/'
    ans_dir = 'RolesSwapped/expected/'
    out_dir = 'RolesSwapped/output/'

class ctlog_xlog_cons_setup(SQLTestCase):
    """
    @gucs gp_create_table_random_default_distribution=off
    """

    sql_dir = 'ctlog_xlog_cons_st/sql/'
    ans_dir = 'ctlog_xlog_cons_st/expected/'
    out_dir = 'ctlog_xlog_cons_st/output/'

class ctlog_xlog_cons_ct(SQLTestCase):
    """
    @gucs gp_create_table_random_default_distribution=off
    """

    sql_dir = 'ctlog_xlog_cons_ct/sql/'
    ans_dir = 'ctlog_xlog_cons_ct/expected/'
    out_dir = 'ctlog_xlog_cons_ct/output/'

class ctlog_xlog_cons_post_reset_ct(SQLTestCase):
    """
    @gucs gp_create_table_random_default_distribution=off
    """

    sql_dir = 'ctlog_xlog_cons_post_reset_ct/sql/'
    ans_dir = 'ctlog_xlog_cons_post_reset_ct/expected/'
    out_dir = 'ctlog_xlog_cons_post_reset_ct/output/'

class ctlog_xlog_cons_cleanup(SQLTestCase):
    """
    @gucs gp_create_table_random_default_distribution=off
    """

    sql_dir = 'ctlog_xlog_cons_cleanup/sql/'
    ans_dir = 'ctlog_xlog_cons_cleanup/expected/'
    out_dir = 'ctlog_xlog_cons_cleanup/output/'

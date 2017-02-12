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
from mpp.lib.gpConfig import GpConfig
from mpp.lib.gpstop import GpStop


import getpass
import os

class PartitionDDLTests(SQLTestCase):
    """
    @product_version gpdb: [4.3-]
    """

    sql_dir = 'sql/'
    ans_dir = 'expected/'

    @classmethod
    def setUpClass(cls):
        super(PartitionDDLTests, cls).setUpClass()

    def get_substitutions(self):
        substitutions = {}
        MYD = self.get_source_dir()
        USER = getpass.getuser()
        substitutions['%PATH%'] = MYD
        substitutions['%USER%'] = USER
        substitutions['@out_dir@'] = self.get_out_dir()
        substitutions["@abs_srcdir@"] = MYD
        substitutions["@DBNAME@"] = os.environ.get('PGDATABASE', getpass.getuser())
        return substitutions
    

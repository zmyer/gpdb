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

import getpass
import os

from tinctest.lib.system import TINCSystem

from mpp.models import GpfdistSQLTestCase

class ErrTblTestCase(GpfdistSQLTestCase):
    """
    @product_version gpdb: [4.3.3.0-4.3.90.0]
    """
    sql_dir = 'sql/'
    ans_dir = 'expected/'
    data_dir = 'data/'

    @classmethod
    def setUpClass(cls):
        TINCSystem.make_dirs(cls.get_data_dir(), ignore_exists_error=True)
        super(ErrTblTestCase, cls).setUpClass()

    def get_substitutions(self):
        """
        Provide path to the script that generates data for error table tests
        """
        substitutions = super(ErrTblTestCase, self).get_substitutions()
        substitutions['@script@'] = os.path.join(self.get_sql_dir(), 'datagen.py')
        substitutions['@user@'] = getpass.getuser()
        return substitutions

#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Copyright (C) 2007 Swaroop C H <swaroop@swaroopchNOSPAM.com>
# Copyright (C) 2013,2017 Robin Schneider <ypid@riseup.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, version 3 of the
# License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

from __future__ import print_function, unicode_literals, absolute_import, division

__license__ = 'AGPL-3.0'
__version__ = '0.5.0'

try:
    import vim
except:
    pass

import subprocess


def safequotes(string):
    return string.replace('"', "'")


def get_vim_eval_result(vimscript_code, fallback=None):
    try:
        return vim.eval(vimscript_code)
    except:
        return fallback


def run_dict(args, state, db_name=None):
    settings_dict_args = get_vim_eval_result('g:lookup_dict_args', [])

    dict_args = []
    if db_name:
        dict_args.extend(['--database', db_name])

    dict_args.extend(settings_dict_args)
    dict_args.extend(args)

    try:
        dict_output = subprocess.check_output(
            ['dict'] + dict_args,
            stderr=subprocess.STDOUT,
            shell=False,
        )
    except subprocess.CalledProcessError as pe:
        if (pe.returncode == 20) and db_name:
            state['DBs_without_hits'].append(db_name)
        else:
            state['DBs_failed'].append(db_name)
    else:
        state['output_lines'].append(dict_output.decode('utf-8').strip().split('\n'))

        if db_name:
            state['DBs_with_hits'].append(db_name)


def get_translation(word):
    state = {
        'DBs_with_hits': [],
        'DBs_without_hits': [],
        'DBs_failed': [],
        'output_lines': [],
    }

    settings_dict_DBs = get_vim_eval_result(
        'g:lookup_databases',
        ['english-german', 'german-english', 'elements', 'none']
    )

    if settings_dict_DBs:
        for db_name in settings_dict_DBs:
            run_dict([word], state, db_name=db_name)
    else:
        run_dict([word], state)

    overview = []
    if state['DBs_with_hits'] and settings_dict_DBs:
        overview.append(
            "{DBs_count} database{plural_suffix} returned entries for \'{word}\': {DBs}".format(
                DBs_count=len(state['DBs_with_hits']),
                plural_suffix='' if len(state['DBs_with_hits']) == 1 else 's',
                word=word,
                DBs=', '.join(str(i) for i in state['DBs_with_hits']),
            )
        )

    if state['DBs_without_hits'] and settings_dict_DBs:
        overview.append(
            "{DBs_count} database{plural_suffix} returned no entries for \'{word}\': {DBs}".format(
                DBs_count=len(state['DBs_without_hits']),
                plural_suffix='' if len(state['DBs_without_hits']) == 1 else 's',
                word=word,
                DBs=', '.join(str(i) for i in state['DBs_without_hits']),
            )
        )

    if state['DBs_failed']:
        overview.append(
            "Lookup{plural_suffix} in {DBs_count} database{plural_suffix} failed: {DBs}".format(
                DBs_count=len(state['DBs_failed']),
                plural_suffix='' if len(state['DBs_failed']) == 1 else 's',
                DBs=', '.join(str(i) for i in state['DBs_failed']),
            )
        )

    state['output_lines'].insert(0, overview)
    #  return state['output_lines']

    output = "\n\n{}\n".format("*" * 72).join(
        ["\n".join(block) for block in state['output_lines']]
    )

    return output


def set_translation_to_vim_var(var_name, word):
    vim.command('silent let {} = "{}"'.format(
        var_name,
        safequotes(get_translation(word)),
    ))


#  if __name__ == '__main__':
#      #  from pprint import pprint
#      #  print(get_translation('test'))
#      print(get_translation('let'))
#      #  set_translation_to_vim_var('test', 'g:lookup_meaning')

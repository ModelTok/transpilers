//=====================================================
// File   :  mean.cxx
// Author :  L. Plagne <laurent.plagne@edf.fr)>
// Copyright (C) EDF R&D,  lun sep 30 14:23:15 CEST 2002
//=====================================================
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//
from sys import argv as sys_argv
from python import Python
from utils.xy_file import read_xy_file
from utilities import MESSAGE, INFOS
from list import List
from string import String
from float import Float64
from int import Int
from io import cout, endl, ofstream, ios

def MESSAGE(msg: String):
    print(msg)

def INFOS(msg: String):
    print(msg)

def mean_calc(tab_sizes: List[Int], tab_mflops: List[Float64], size_min: Int, size_max: Int) -> Float64:

    var size: Int = len(tab_sizes)
    var nb_sample: Int = 0
    var mean: Float64 = 0.0

    for i in range(size):
        if (tab_sizes[i] >= size_min) and (tab_sizes[i] <= size_max):
            nb_sample += 1
            mean += tab_mflops[i]

    if nb_sample == 0:
        INFOS("no data for mean calculation")
        return 0.0

    return mean / nb_sample

class Lib_Mean:

    var _mean_in_cache: Float64
    var _mean_out_of_cache: Float64
    var _lib_name: String

    def __init__(self):
        self._lib_name = ""
        self._mean_in_cache = 0.0
        self._mean_out_of_cache = 0.0
        MESSAGE("Lib_mean Default Ctor")
        MESSAGE("!!! should not be used")
        exit(0)

    def __init__(self, name: String, mic: Float64, moc: Float64):
        self._lib_name = name
        self._mean_in_cache = mic
        self._mean_out_of_cache = moc
        MESSAGE("Lib_mean Ctor")

    def __init__(self, lm: Lib_Mean):
        self._lib_name = lm._lib_name
        self._mean_in_cache = lm._mean_in_cache
        self._mean_out_of_cache = lm._mean_out_of_cache
        MESSAGE("Lib_mean Copy Ctor")

    def __del__(self):
        MESSAGE("Lib_mean Dtor")

    def __lt__(self, right: Lib_Mean) -> Bool:
        #return ( this->_mean_out_of_cache > right._mean_out_of_cache) ;
        return (self._mean_in_cache > right._mean_in_cache)


def main() raises:

    var argv: List[String] = List[String]()
    # Simulate argc/argv via sys.argv
    var py_sys = Python.import_module("sys")
    var py_argv = py_sys.argv
    for i in range(len(py_argv)):
        argv.append(String(py_argv[i]))

    var argc: Int = len(argv)
    if argc < 6:
        INFOS("!!! Error ... usage : main what mic Mic moc Moc filename1 finename2...")
        exit(0)
    INFOS(argc)

    var min_in_cache: Int = Int(argv[2])
    var max_in_cache: Int = Int(argv[3])
    var min_out_of_cache: Int = Int(argv[4])
    var max_out_of_cache: Int = Int(argv[5])

    var s_lib_mean: List[Lib_Mean] = List[Lib_Mean]()

    for i in range(6, argc):
        var filename: String = argv[i]

        INFOS(filename)

        var mic: Float64 = 0.0
        var moc: Float64 = 0.0

        # {
        var tab_sizes: List[Int] = List[Int]()
        var tab_mflops: List[Float64] = List[Float64]()

        read_xy_file(filename, tab_sizes, tab_mflops)

        mic = mean_calc(tab_sizes, tab_mflops, min_in_cache, max_in_cache)
        moc = mean_calc(tab_sizes, tab_mflops, min_out_of_cache, max_out_of_cache)

        var cur_lib_mean: Lib_Mean = Lib_Mean(filename, mic, moc)

        s_lib_mean.append(cur_lib_mean)
        # }

    # Sort s_lib_mean using operator< (descending _mean_in_cache)
    # We'll use a simple bubble sort or the built-in sort with key lambda? Since we need to replicate multiset ordering,
    # we can implement insertion sort or just sort after all insertions. We'll use a simple insertion into a sorted list.
    # Alternatively, we can sort the whole list after insertion using a custom comparator that mirrors __lt__.
    # Since __lt__ returns _mean_in_cache > right._mean_in_cache (descending), we need to sort accordingly.
    # Mojo's List.sort() does not support custom comparator yet? We'll implement a manual bubble sort to ensure strict ordering.
    # Actually we can use the __lt__ function in a sort, but we'll just do a simple loop to maintain sorted order on insertion.
    # For simplicity, we'll sort after all inserts using a custom comparison (but we can't call sort with custom key easily in Mojo).
    # We'll just do a simple O(n^2) insertion sort loop after the fact.
    var n: Int = len(s_lib_mean)
    if n > 1:
        for i in range(1, n):
            var key: Lib_Mean = s_lib_mean[i]
            var j: Int = i - 1
            while j >= 0 and key < s_lib_mean[j]:
                s_lib_mean[j + 1] = s_lib_mean[j]
                j -= 1
            s_lib_mean[j + 1] = key

    cout << "<TABLE BORDER CELLPADDING=2>" << endl
    cout << "  <TR>" << endl
    cout << "    <TH ALIGN=CENTER> " << argv[1] << " </TH>" << endl
    cout << "    <TH ALIGN=CENTER> <a href=\"#mean_marker\"> in cache <BR> mean perf <BR> Mflops </a></TH>" << endl
    cout << "    <TH ALIGN=CENTER> in cache <BR> % best </TH>" << endl
    cout << "    <TH ALIGN=CENTER> <a href=\"#mean_marker\"> out of cache <BR> mean perf <BR> Mflops </a></TH>" << endl
    cout << "    <TH ALIGN=CENTER> out of cache <BR> % best </TH>" << endl
    cout << "    <TH ALIGN=CENTER> details </TH>" << endl
    cout << "    <TH ALIGN=CENTER> comments </TH>" << endl
    cout << "  </TR>" << endl

    var is: Int = 0
    var best: Lib_Mean = s_lib_mean[0]

    for is in range(len(s_lib_mean)):
        var cur: Lib_Mean = s_lib_mean[is]
        cout << "  <TR>" << endl
        cout << "     <TD> " << cur._lib_name << " </TD>" << endl
        cout << "     <TD> " << cur._mean_in_cache << " </TD>" << endl
        cout << "     <TD> " << 100 * (cur._mean_in_cache / best._mean_in_cache) << " </TD>" << endl
        cout << "     <TD> " << cur._mean_out_of_cache << " </TD>" << endl
        cout << "     <TD> " << 100 * (cur._mean_out_of_cache / best._mean_out_of_cache) << " </TD>" << endl
        cout << "     <TD> " << "<a href=\"#" << cur._lib_name << "_" << argv[1] << "\">snippet</a>/" \
             << "<a href=\"#" << cur._lib_name << "_flags\">flags</a>  </TD>" << endl
        cout << "     <TD> " << "<a href=\"#" << cur._lib_name << "_comments\">click here</a>  </TD>" << endl
        cout << "  </TR>" << endl

    cout << "</TABLE>" << endl

    var output_file: ofstream = ofstream("../order_lib", ios.out)

    for is in range(len(s_lib_mean)):
        var cur: Lib_Mean = s_lib_mean[is]
        output_file << cur._lib_name << endl

    output_file.close()

def mean_calc(tab_sizes: List[Int], tab_mflops: List[Float64], size_min: Int, size_max: Int) -> Float64:
    var size: Int = len(tab_sizes)
    var nb_sample: Int = 0
    var mean: Float64 = 0.0

    for i in range(size):
        if (tab_sizes[i] >= size_min) and (tab_sizes[i] <= size_max):
            nb_sample += 1
            mean += tab_mflops[i]

    if nb_sample == 0:
        INFOS("no data for mean calculation")
        return 0.0

    return mean / nb_sample
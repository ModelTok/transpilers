# //=====================================================
# // File   :  regularize.cxx
# // Author :  L. Plagne <laurent.plagne@edf.fr)>        
# // Copyright (C) EDF R&D,  lun sep 30 14:23:15 CEST 2002
# //=====================================================
# // 
# // This program is free software; you can redistribute it and/or
# // modify it under the terms of the GNU General Public License
# // as published by the Free Software Foundation; either version 2
# // of the License, or (at your option) any later version.
# // 
# // This program is distributed in the hope that it will be useful,
# // but WITHOUT ANY WARRANTY; without even the implied warranty of
# // MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# // GNU General Public License for more details.
# // You should have received a copy of the GNU General Public License
# // along with this program; if not, write to the Free Software
# // Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
# // 
# include "utilities.h"
# include <vector>
# include <string>
# include <iostream>
# include <fstream>
# include "bench_parameter.hh"
# include <set>

# using namespace std;

from python import Python
import sys
from sys import exit, argv as sys_argv

def INFOS(msg: String):
    print(msg)

def SCRUTE(val: Int):
    print("SCRUTE:", val)

def read_xy_file(filename: String, tab_sizes: List[Int], tab_mflops: List[Float64]):
    input_file = open(filename, "r")
    if not input_file:
        INFOS("!!! Error opening " + filename)
        exit(0)

    nb_point = 0
    size = 0
    mflops = 0.0

    while True:
        line = input_file.readline()
        if not line:
            break
        parts = line.split()
        if len(parts) >= 2:
            size = Int(parts[0])
            mflops = Float64(parts[1])
            nb_point += 1
            tab_sizes.append(size)
            tab_mflops.append(mflops)
    SCRUTE(nb_point)

    input_file.close()

def regularize_curve(filename: String,
                     tab_mflops: List[Float64],
                     tab_sizes: List[Int],
                     start_cut_size: Int,
                     stop_cut_size: Int):
    size = len(tab_mflops)
    output_file = open(filename, "w")

    i = 0

    while tab_sizes[i] < start_cut_size:
        output_file.write(str(tab_sizes[i]) + " " + str(tab_mflops[i]) + "\n")
        i += 1

    output_file.write("\n")

    while tab_sizes[i] < stop_cut_size:
        i += 1

    while i < size:
        output_file.write(str(tab_sizes[i]) + " " + str(tab_mflops[i]) + "\n")
        i += 1

    output_file.close()

def main(argv: List[String]):
    #   input data

    if len(argv) < 4:
        INFOS("!!! Error ... usage : main filename start_cut_size stop_cut_size regularize_filename")
        exit(0)
    INFOS(str(len(argv)))

    start_cut_size = Int(argv[2])
    stop_cut_size = Int(argv[3])

    filename = argv[1]
    regularize_filename = argv[4]

    INFOS(filename)
    INFOS("start_cut_size=" + str(start_cut_size))

    tab_sizes: List[Int] = List[Int]()
    tab_mflops: List[Float64] = List[Float64]()

    read_xy_file(filename, tab_sizes, tab_mflops)

    #   regularizeing

    regularize_curve(regularize_filename, tab_mflops, tab_sizes, start_cut_size, stop_cut_size)

if __name__ == "__main__":
    main(sys_argv)
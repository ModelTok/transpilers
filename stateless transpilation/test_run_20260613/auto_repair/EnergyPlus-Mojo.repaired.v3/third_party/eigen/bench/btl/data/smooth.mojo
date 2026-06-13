//=====================================================
// File   :  smooth.cxx
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
from sys import argv, exit
from typing import List

# Simulate INFOS and SCRUTE macros from utilities.h
def INFOS(msg: str):
    print(msg)

def SCRUTE(val):
    print(val)

def read_xy_file(filename: str, tab_sizes: List[int], tab_mflops: List[float]):
    input_file = open(filename, 'r')
    if not input_file:
        INFOS("!!! Error opening " + filename)
        exit(0)
    nb_point = 0
    size = 0
    mflops = 0.0
    for line in input_file:
        parts = line.split()
        if len(parts) >= 2:
            size = int(parts[0])
            mflops = float(parts[1])
            nb_point += 1
            tab_sizes.append(size)
            tab_mflops.append(mflops)
    SCRUTE(nb_point)
    input_file.close()

def write_xy_file(filename: str, tab_sizes: List[int], tab_mflops: List[float]):
    output_file = open(filename, 'w')
    for i in range(len(tab_sizes)):
        output_file.write(str(tab_sizes[i]) + " " + str(tab_mflops[i]) + "\n")
    output_file.close()

def smooth_curve(tab_mflops: List[float], smooth_tab_mflops: List[float], window_half_width: int):
    window_width = 2 * window_half_width + 1
    size = len(tab_mflops)
    sample = [0.0] * window_width
    for i in range(size):
        for j in range(window_width):
            shifted_index = i + j - window_half_width
            if shifted_index < 0:
                shifted_index = 0
            if shifted_index > size - 1:
                shifted_index = size - 1
            sample[j] = tab_mflops[shifted_index]
        smooth_tab_mflops.append(weighted_mean(sample))

def centered_smooth_curve(tab_mflops: List[float], smooth_tab_mflops: List[float], window_half_width: int):
    max_window_width = 2 * window_half_width + 1
    size = len(tab_mflops)
    for i in range(size):
        sample = deque()
        sample.append(tab_mflops[i])
        for j in range(1, window_half_width + 1):
            before = i - j
            after = i + j
            if (before >= 0) and (after < size):
                sample.appendleft(tab_mflops[before])
                sample.append(tab_mflops[after])
        smooth_tab_mflops.append(weighted_mean(list(sample)))

def weighted_mean(data: List[float]) -> float:
    mean = 0.0
    for i in range(len(data)):
        mean += data[i]
    return mean / float(len(data))

def main():
    # input data
    if len(argv) < 3:
        INFOS("!!! Error ... usage : main filename window_half_width smooth_filename")
        exit(0)
    INFOS(str(len(argv)))
    window_half_width = int(argv[2])
    filename = argv[1]
    smooth_filename = argv[3]
    INFOS(filename)
    INFOS("window_half_width=" + str(window_half_width))
    tab_sizes = []
    tab_mflops = []
    read_xy_file(filename, tab_sizes, tab_mflops)
    # smoothing
    smooth_tab_mflops = []
    #smooth_curve(tab_mflops,smooth_tab_mflops,window_half_width);
    centered_smooth_curve(tab_mflops, smooth_tab_mflops, window_half_width)
    # output result
    write_xy_file(smooth_filename, tab_sizes, smooth_tab_mflops)

if __name__ == "__main__":
    main()
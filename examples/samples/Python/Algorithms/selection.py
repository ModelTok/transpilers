#!/usr/bin/env python
# coding: utf-8



'''
Copyright [2020] [Priyanka prasad ] 
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
'''
def selectionSort(array):
  n = len(array)
  for i in range(n):
    minimum = i

    for j in range(i+1, n):
      if (array[j] < array[minimum]):
        minimum = j

    temp = array[i]
    array[i] = array[minimum]
    array[minimum] = temp
    
  return array

array = [13, 4, 9, 5, 3, 16, 12]
print(selectionSort(array))

'''
Copyright 2020 Bryan
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

def recursive_binary_search(target, the_values, first, last):
    if first > last:
        return False
    else:
        mid = (first + last) // 2
        
        if the_values[mid] == target:
            return True
        
        elif target < the_values[mid]:
            return recursive_binary_search(target, the_values, first, mid - 1)

        else:
            return recursive_binary_search(target, the_values, mid + 1, last)


if __name__ == "__main__":
    sequence = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    
    number_found = recursive_binary_search(1, seq, 0, len(seq) - 1)
    
    print(number_found)
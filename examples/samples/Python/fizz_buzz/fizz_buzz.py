'''
Copyright 2020 Abdul Majed
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

def FizzBuzz(n):
	for i in range(1,n+1):
		s=''
		if i%3 == 0:
			s+="Fizz"
		if i%5 == 0:
			s+="Buzz"
		if s == '':
			print(i)
		else:
			print(s)

FizzBuzz(50)


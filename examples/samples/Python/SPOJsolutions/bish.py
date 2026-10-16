'''	
You can use below code snippet to read line by line, till end of file

line = obj.readline()
while(line != ''):

    # Do Something

    line = obj.readline()
'''


import sys

for p in sys.stdin:
	if int(p)==1 :
		print(int(p))
	else:
		print(2*int(p)- 2)

n = int(input())
i = 1
while n:
	k = int(input())
	Str = input()
	ar = [0]*8
	for x in range(len(Str)-2):
		if Str[x:x+3] == "TTT":
			ar[0]+=1;
		elif Str[x:x+3] == "TTH":
			ar[1]+=1;
		elif Str[x:x+3] == "THT":
			ar[2]+=1;
		elif Str[x:x+3] == "THH":
			ar[3]+=1;
		elif Str[x:x+3] == "HTT":
			ar[4]+=1;
		elif Str[x:x+3] == "HTH":
			ar[5]+=1;
		elif Str[x:x+3] == "HHT":
			ar[6]+=1;
		elif Str[x:x+3] == "HHH":
			ar[7]+=1;
	print(i,end=' ')
	print(*ar,end=' ')
	print()
	i += 1
	n-=1

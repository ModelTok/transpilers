#include <iostream>
#include <stdio.h>

using namespace std;

typedef long long typ;
typedef long siz;


void display(typ lis[], siz n){
	for (siz i=0 ; i<n ; ++i)
		cout<<lis[i]<<" ";
	cout<<endl;
}


 

void merge_it(typ lis1[],typ lis2[],typ lis[], siz n1, siz n2, siz n){
	siz p=0,q=0,r=0;
	while(p<n1 && q<n2){
		if(lis1[p] <= lis2[q])
			lis[r++] = lis1[p++];		
		else
			lis[r++] = lis2[q++];
	}
	while(p<n1){
		lis[r++] = lis1[p++];
	}
	while(q<n2){
		lis[r++] = lis2[q++];
	}
}


void merge_sort(typ lis[], siz n){
	if(n>1){
		siz pos = n/2;
		siz k = 0;
		typ lis1[pos],lis2[n-pos];
		for(siz i=0;i<pos;++i){
			lis1[i] = lis[k++];
		}
		for(siz i=0;i<n-pos;++i){
			lis2[i] = lis[k++];
		}
		merge_sort(lis1,pos);
		merge_sort(lis2,n-pos);
		merge_it(lis1,lis2,lis,pos,n-pos,n);
	}
}



int main(){
	typ Ar[100001];
	siz i = 0;
	typ n;
	while(scanf("%lld",&n) != EOF){
		Ar[i++] = n;
	}
	merge_sort(Ar,i);
	display(Ar,i);
return 0;
}

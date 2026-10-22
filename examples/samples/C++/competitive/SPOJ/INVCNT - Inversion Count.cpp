
#include <iostream>
#include <stdio.h>
using namespace std;

typedef long long typ;
typedef long long siz;

 

siz countinv = 0;
void count_invertion_merge_it(typ lis1[],typ lis2[],typ lis[], siz n1, siz n2, siz n){
	siz p=0,q=0,r=0,counter=0;
	while(p<n1 && q<n2){
		if(lis1[p] <= lis2[q]){
			countinv += counter;
			lis[r++] = lis1[p++];
			
		}
		else{
				counter++;
			lis[r++] = lis2[q++];
		}
	}
	while(p<n1){
	    countinv += counter;
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
		count_invertion_merge_it(lis1,lis2,lis,pos,n-pos,n);
	}
}

int main(){
	siz n,t;
	cin>>t;
	while(t--){
		char ignore[10];
		cin.getline(ignore,10);
		cin>>n;
		countinv = 0;
		typ Ar[n];
		for(siz i=0; i<n; ++i)
			cin>>Ar[i];
		merge_sort(Ar,n);
		cout<<countinv<<endl;
	}
return 0;
}







#include <iostream>
#include <stdio.h>
using namespace std;

typedef long long ityp;
typedef long long typ;

ityp bin_search_first(typ ar[],ityp low, ityp high, typ x){
    ityp ret = -1;
    while(low <= high){
	ityp mid = (high + low)/2;
	if(ar[mid] == x){
	    ret = mid;
	    high = mid - 1;
	}
	else if(ar[mid] < x)	low = mid + 1;
	else high = mid - 1;
    }
    return ret;
}

int main(){
    ityp N, Q;
    cin>>N>>Q;
    typ Ar[N],k;
    for(ityp i=0;i<N;++i)
		scanf("%lld",&Ar[i]);
    while(Q--){
	scanf("%lld",&k);
	printf("%lld\n",bin_search_first(Ar,0,N-1,k));
    }
    return 0;
}

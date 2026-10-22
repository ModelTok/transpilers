#include <iostream>
#include <vector>
#include <math.h>
using namespace std;
typedef long long typ;

int main() {
	int t;
	cin>>t;
	while(t--){
		typ m,n,k;
		cin>>m>>n;
		typ sq = sqrt(n);
		typ dubsq = sqrt(sq);
		vector<bool> prime(sq+1);
		vector<bool> myprime(n-m+1);
		fill(prime.begin(),prime.end(),true);
		fill(myprime.begin(),myprime.end(),true);
		prime[0]=prime[1]=false;
		for(int i=2;i<=dubsq;++i){
			if(prime[i]){
				for(int j=i*i;j<=sq;j+=i){
					prime[j] = false;
				}
			}
		}
		
		for(int i=0;i<=sq;++i){
			if(prime[i]){
				k = ((int)(m/i)*i);
				for(int x=k;x<=n;x+=i){
						if(x>=m && x!=i) {
							myprime[x-m] = false; 
						}
				}
			}
		}
		for(int i=0;i<n-m+1;++i)
			if(myprime[i]) {
				if(i+m!=1){ cout<<i+m<<endl;
						}
				}
		cout<<endl;
	}
	return 0;
}

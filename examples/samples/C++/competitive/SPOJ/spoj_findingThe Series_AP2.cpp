
#include <iostream>
using namespace std;
typedef long long ll; 
int main() {
	ll n,d,s,a3,l3,a;
	int t;
	cin>>t;
	while(t--){
		cin>>a3>>l3>>s;
		n = (s*2)/(a3+l3);
		d = (l3-a3)/(n-5);
		a = a3 - 2*d;
		cout<<n<<endl;
		for(ll i=0;i<n;++i){
			cout<<a+i*d<<" ";
		}
	}
	return 0;
}

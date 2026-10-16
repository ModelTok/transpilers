
#include <bits/stdc++.h>
using namespace std;
using ll = long long;
int main() {
    ll t;
    cin>>t;
    while(t--){
        ll n,k;
        cin>>n>>k;
        ll a[10000];
        ll min=1000000000000, min2=-1;
        for(int i=0;i<n;i++){
            cin>>a[i];
        }
        for(ll i=0;i<n;i++){
            if(k%a[i]==0){
                ll temp=k/a[i]-1;
                if(temp<min){
                    min=temp;
                    min2=a[i];
                }
            }
        }
        cout<<min2<<endl;
    }
	return 0;
}

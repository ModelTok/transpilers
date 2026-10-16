
#include <iostream>
#include<bits/stdc++.h>
#define ll long long
using namespace std;

int main() {
	ll t;
	cin>>t;
	while(t--){
	    ll n,q;
	    cin>>n>>q;
	    while(q--){
	        ll l,r,v,sum=0;
	        cin>>l>>r>>v;
	        for(int i=l;i<=r;i++){
	            sum+=v;
	        }
	    }
	    cout<<sum<<endl;
	}
}

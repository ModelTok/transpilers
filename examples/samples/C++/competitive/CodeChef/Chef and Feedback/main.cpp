

#include <iostream>
#include<bits/stdc++.h>

#define ll long long

using namespace std;

void solve()
{
    string s;
    cin>>s;
    auto i=s.find("010");
    auto j=s.find("101");

    if(i<s.size()||j<s.size()){
        cout<<"Good";
        return ;
    }
    cout<<"Bad";
}

int main()
{
    ll t;
    cin>>t;
    while(t--){
        solve();
        cout<<endl;
    }
    return 0;
}


#include<bits/stdc++.h>
#define ll long long

using namespace std;


void solve()
{
    int n;
    cin>>n;
    int a[n];
    for(int i=0;i<n;i++){
        cin>>a[i];
    }
    ll dp[n];
    fill(dp,dp+n,1ll);
    ll ans = 1;
    for(int i=1;i<n;i++){
        if(a[i] >= a[i-1]) dp[i] += dp[i-1];
        ans += dp[i];
    }
    cout<< ans << "\n";
}

int main()
{
    int t;
    cin>>t;
    for(int i=0;i<t;i++){
        solve();
    }
    return 0;
}

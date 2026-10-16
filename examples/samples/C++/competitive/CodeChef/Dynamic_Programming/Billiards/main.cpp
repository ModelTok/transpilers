#include <iostream>
#include <bits/stdc++.h>
#define Int long long
#define MOD 1000000009

using namespace std;

int main()
{
    int t;
    cin>>t;
    vector<int> dp(1000001,0);
     dp[0] = 0;
     dp[1] = 0;
     dp[2] = 1;
     dp[3] = 1;
    for(int i=4;i<dp.size();i++){
        int op1=dp[i-2];
        int op2=dp[i-3];
        dp[i] = (dp[i]+op1+op2)%MOD;
    }
    while(t--){
        int n;
        cin>>n;
        cout<<dp[n]<<endl;
    }
    return 0;
}

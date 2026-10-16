
#include<bits/stdc++.h>
#define Mx 1000000000005
#define ll long long
#define pi 3.141592653
#define vi vector<ll>
#define Mo 1000000007
#define mp make_pair
#define M map<ll,ll>
#define fr(i,a,b) for(ll i=a;i<b;i++)
#define vii vector<pair<ll,ll> >
#define fi first
#define se second
#define pb push_back
#define ld long double
#define fill(a,x) memset(a,x,sizeof(a))
using namespace std;
int main()
{
  ll n=100005,x;

  ll p[n+1]={0};
  fr(i,2,n+1)
  {
    if(!p[i])
    {
      for(ll j=i;j<n+1;j+=i)
        p[j]++;
    }
  }

  ll dp[n+1][6];
  fill(dp,0);

  fr(i,1,n+1)
    fr(k,1,6)
    {
      if(p[i]==k)
        dp[i][k]=1+dp[i-1][k];
      else
        dp[i][k]=dp[i-1][k];
    }


  ll t; cin>>t;
  while(t--)
  {
    ll a,b,k; cin>>a>>b>>k;
    cout<<dp[b][k]-dp[a-1][k]<<endl;
  }

}

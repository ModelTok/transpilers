
#include <iostream>
#include <cstdio>
#include <cstring>
using namespace std;
int n,k,p,a[55][35];
int dp[55][1505];

void solve()
{
    scanf("%d%d%d",&n,&k,&p);
    memset(dp,0xc0,sizeof(dp));
    dp[0][0] = 0;
    for(int i=0; i<n; i++)
    {
        memcpy(dp[i+1],dp[i],sizeof(dp[0]));
        for(int j = 0, s = 0; j<k; j++)
        {
            scanf("%d",&a[i][j]);
            s+=a[i][j];
            for(int l = 0;l+j+1<=p;l++)
                dp[i+1][l+j+1] = max(dp[i][l] + s, dp[i+1][l+j+1]);
        }
    }
    printf("%d\n",dp[n][p]);
}
int main()
{
    int t,i = 1;
    scanf("%d",&t);
    while(t--)
    {
        printf("Case #%d: ",i);
        solve();
        i++;
    }
    return 0;
}

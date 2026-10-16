
#include <cstdio>
#include <algorithm>
#include <cstring>
using namespace std;
int v[100005];
int sol[105];
int main()
{
    int t,n,s,j,i,cnt = 0;
    scanf("%d",&t);
    for(j=1;j<=t;j++)
    {
        memset(v, 0, sizeof(v));
        cnt = 0;
        scanf("%d%d",&n,&s);
        for(i=1;i<=n;i++)
            scanf("%d",&v[i]);
        sort(v+1,v+n+1);
        for(i=1;i<=n;i++)
        {
            if(s-v[i]>=0)
            {
                s -= v[i];
                cnt++;
            }
            else
                break;
        }
        sol[j] = cnt;
    }
    for(j=1;j<=t;j++)
        printf("Case #%d: %d\n",j,sol[j]);
    return 0;
}

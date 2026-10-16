
#include <cstdio>
#include <cstring>
using namespace std;
int ans;
int v[200005];
void solve()
{
    for(int i = 1;i<= 200000; i++)
        v[i] = 0;
    int n,j,l,lmax = 0,dr = 1,current;
    scanf("%d",&n);
    scanf("%d%d",&v[1],&v[2]);
    dr = 2;
    current = v[2]-v[1];
    l = 2;
    for(j=3;j<=n;j++)
    {
        scanf("%d",&v[j]);
        dr++;
        if(v[dr]-v[dr-1] == current)
            l++;
        else
        {
            if(l>lmax)
                lmax = l;
            l = 2;
            current = v[dr] - v[dr-1];
        }
    }
    if(lmax == 0 || lmax < l)
        lmax = l;
    ans = lmax;
}
int main()
{
    int t,i=0;
    scanf("%d",&t);
    while(t--)
    {
        i++;
        solve();
        printf("Case #%d: %d\n",i,ans);
    }
    return 0;
}

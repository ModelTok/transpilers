
#include <cstdio>
#include <vector>
using namespace std;

bool check(vector<int> &arr, int mid, int k)
{
    int cnt = 0;
    for(int i=1; i<arr.size(); i++)
    {
        int diff = arr[i]-arr[i-1];
        int sessNeeded = (diff-1)/mid;
        cnt += sessNeeded;
        if(cnt > k)
            return false;
    }
    return true;
}



int solve()
{
    int n, k;
    scanf("%d%d",&n,&k);
    vector<int> arr(n);
    for(int i=0; i<n; i++)
        scanf("%d",&arr[i]);
    int maxDiff = 0;
    int ans = 0;
    for(int i=1; i<n; i++)
        maxDiff = max(maxDiff,arr[i]-arr[i-1]);
    if (maxDiff==1)
        return 1;
    int s = 1, e = maxDiff;
    while(s<=e)
    {
        int mid = s + (e-s)/2;
        if(check(arr,mid,k))
        {
            ans = mid;
            e = mid-1;
        }
        else s = mid+1;
    }
    return ans;
}

int main()
{
    int t,x;
    scanf("%d",&t);
    int i = 1;
    while(t--)
    {
        x = solve();
        printf("Case #%d: %d\n",i,x);
        i+=1;
    }
    return 0;
}

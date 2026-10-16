
#include<bits/stdc++.h>
#define ll long long
using namespace std;
ll max_subarray(ll a[],int n)
{
    ll curr_sum=0,max_sum=INT_MIN;
    for(int i=0;i<n;i++)
    {
        curr_sum=max(curr_sum+a[i],a[i]);
        max_sum=max(max_sum,curr_sum);
    }
    return max_sum;
}
int main()
{
    int t;
    cin>>t;
    while(t--)
    {
        ll n,k;
        cin>>n>>k;
        ll arr[n];
        for(int i=0;i<n;i++)
        cin>>arr[i];
        ll z=2*n;
        ll b[z];
        for(int i=0;i<z;i++)
        {
            b[i]=arr[i%n];
        }
        if(k==1)
        {
            cout<<max_subarray(arr,n);
        }
        else
        {
            ll max_sum=max_subarray(b,z);
            ll sum=0;
            for(int i=0;i<n;i++)
                sum+=arr[i];
            if(sum<0)
                cout<<max_sum;
            else
                cout<<max_sum+(k-2)*sum;
        }
        cout<<"\n";
    }
}

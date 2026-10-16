
#include <iostream>
#include<vector>
#include<iterator>
#include<algorithm>
#include <bits/stdc++.h>

using namespace std;

void solve(int n, int m)
{
    int temp;
    vector <int> unfinished, completed, total, chef, asst;
    for(int i = 0; i<m;i++){
        cin>>temp;
        completed.push_back(temp);
    }
    for(int i=1;i<=n;++i){
        total.push_back(i);
    }
    sort(total.begin(), total.end());
    sort(completed.begin(), completed.end());
    set_difference(
                   total.begin(),
                   total.end(),
                   completed.begin(),
                   completed.end(),
                   inserter(unfinished, unfinished.begin())
    );
    sort(unfinished.begin(), unfinished.end());
    int count = 0;
    for(auto i:unfinished){
        if(count%2==0) chef.push_back(i);
        else asst.push_back(i);
        count++;
    }

    for(auto i:chef) cout << i <<' '; cout<<'\n';
    for(auto i:asst) cout << i <<' '; cout<<'\n';
}

int main()
{
    ios::sync_with_stdio(false); cin.tie(0);
    int t,n,m,temp,counter=1;
    vector<int> chef,asst;
    cin>>t;
    while(t--){
        cin>>n>>m;
        solve(n,m);
    }
    return 0;
}

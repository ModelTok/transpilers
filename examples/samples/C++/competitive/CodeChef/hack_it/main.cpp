
#include <iostream>
#include <bits/stdc++.h>
using namespace std;


int main()
{
    int t;
    vector<int>vec;
    cin>>t;
    while(t--){
        int n;
        cin>>n;
        while(n!=0){
            int num = n%10;
            vec.push_back(num);
            n/=10;
        }
        for(int i=0;i<vec.size();i++){
            vec[i] = vec[i] - 2;
        }
        reverse(vec.begin(),vec.end());
        for(int x:vec){
            cout<<x;
        }
        cout<<"\n";
    }
    return 0;
}

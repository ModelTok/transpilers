
#include <iostream>
#include<bits/stdc++.h>

using namespace std;

int main()
{
    int t;
    cin>>t;
    while(t--){
        int game;
        cin>>game;
        while(game--){
            int init, n, final, ans=0;
            cin>>init>>n>>final;
            if(n%2==0){
                ans/=2;
            }
            else{
                if(init==final){
                    ans = n/2;
                }
                else{
                    ans=n/2+1;
                }
            }
            cout<<ans<<endl;
        }
    }
    return 0;
}

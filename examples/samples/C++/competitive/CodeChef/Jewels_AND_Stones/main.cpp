
#include <iostream>
#include<bits/stdc++.h>

using namespace std;

int main()
{
    int t;
    cin>>t;
    while(t--){
        string jewel,stone;
        cin>>stone>>jewel;
        set<char> S(stone.begin(),s.end());
        int cnt = 0;
        for(int i=0;i<jewel.size();i++){
            if(S.count(t[i]))
                cnt++;
        }
        cout<<cnt<<endl;
    }
    return 0;
}

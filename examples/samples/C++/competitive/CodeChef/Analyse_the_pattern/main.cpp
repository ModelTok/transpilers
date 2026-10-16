
#include <iostream>
#include <bits/stdc++.h>
#define ll long long
using namespace std;

int main() {
	int t;
	vector<char> s={'S','S','E','C'};
	int vec[7] = {1,2,3,4,3,2,1};
	cin>>t;
	while(t--){
	    int n;
	    cin>>n;
	    int r = n%7-1<0?n%7:n%7-1;
	    int val = vec[r];
	    int res;
        for(int i=0;i<val;i++){
            res = s[i];
            cout<<res<<" ";
        }
        cout<<"\n";
	}
	return 0;
}

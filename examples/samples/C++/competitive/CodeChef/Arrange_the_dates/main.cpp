
#include <iostream>
#include <bits/stdc++.h>
#define ll long long
using namespace std;

int main() {
    vector<string> vec;
	int n;
	cin>>n;
	for(int i=0;i<n;i++){
        string val;
        cin>>val;
        vec.push_back(val);
	}
	sort(vec.begin(),vec.end());
	for(auto x:vec){
        cout<<x<<"\n";
	}
	return 0;
}

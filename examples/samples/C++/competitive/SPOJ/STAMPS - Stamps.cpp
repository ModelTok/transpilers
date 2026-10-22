#include <iostream>
#include <algorithm>
#include <vector>
using namespace std;

int main() {
	long t,box,screw,temp,i=1;
	cin>>t;
	while(t--){
		cin>>screw>>box;
		vector<long> scr;
		while(box--){
			cin>>temp;
			scr.push_back(temp);
		}
		sort(scr.begin(),scr.end());
		reverse(scr.begin(),scr.end());
		long count=1,max=scr[0];
		long flag = 0,n=scr.size();
		while(count<=n){
			if(max>=screw)	{
				flag = 1;
				break;
				}
			else max+=scr[count++];
			
		}
		if(flag)
			cout<<"Scenario #"<<i++<<":"<<endl<<count<<endl;
		else
			cout<<"Scenario #"<<i++<<":"<<endl<<"impossible"<<endl;
	
		if(t!=0) cout<<endl;
	}
	return 0;
}

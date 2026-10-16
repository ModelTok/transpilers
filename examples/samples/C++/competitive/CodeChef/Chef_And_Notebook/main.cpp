
#include <iostream>
using namespace std;

int main() {
	long long t,x,y,k,n;
	long long cost, page;
	cin>>t;
	while(t--){
	    cin>>x>>y>>k>>n;
	    if(x <= y){
	        cout<<"LuckyChef"<<endl;
	        continue;
	    }
	    long long gap = x-y;
	    bool flag = false;
	    while(n--){
	        cin>>page>>cost;
	        if((cost<=k) && (page>=gap))
	            flag = true;
	    }
	    if(flag == false)
	        cout<<"UnluckyChef"<<endl;
        else
            cout<<"LuckyChef"<<endl;
	}

	return 0;
}

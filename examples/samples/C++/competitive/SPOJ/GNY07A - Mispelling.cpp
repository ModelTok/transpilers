#include <iostream>
using namespace std;

int main() {
	int t,c=1;
	cin>>t;
	while(t--){
		int n,i=0;
		char str[81];
		cin>>n>>str;
		i = n-1;
		while(str[i+1]!='\0'){
			str[i]=str[i+1];
			i++;
		}
		str[i] = '\0';
		cout<<c++<<" "<<str<<endl;;
	}
	return 0;
}

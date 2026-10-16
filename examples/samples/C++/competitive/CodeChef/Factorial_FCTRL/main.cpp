
#include <iostream>
#include <bits/stdc++.h>

using namespace std;

int main() {

    int T;
    cin>>T;
    for(int i = 0;i<T;i++){

        int n;
        cin>>n;
        int count = 0;
        for(int j=5;j<=n;j=j*5){
            count = count + (n/j);
        }
        std::cout << count << std::endl;
    }
	return 0;
}

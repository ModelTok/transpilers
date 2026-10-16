
#include <iostream>

using namespace std;

int main()
{
    int n,m;
    cin>>n>>m;
    int out = n-m;
    if(out%10==9)
        out--;
    else
        out++
        ;
    cout<<out<<endl;
    return 0;
}

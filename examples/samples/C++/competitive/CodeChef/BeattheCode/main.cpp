
#include <iostream>

using namespace std;

int main()
{
    int i =-1;
    while((i--)==--i){
        i-=i++;
    }
    cout<<i<<endl;
    return 0;
}


#include <iostream>

using namespace std;

int find()
{
    int no, q=0;
    cin>>no;
    int count = no;
    long long int speed[no];
    for(int i=0;i<no;i++)
        cin>>speed[i];

    for(int i=1;i<no;i++)
	{
		q=0;
		for(int j=0;j<i;j++)
		{
			if(speed[i]>speed[j])
			q=1;
		}
		if(q==1)
		count=count-1;
    }
    return count;
}


int main()
{
    int t,i=0;
    cin>>t;
    int temp = t;
    int ans[t];
    while(t--){
        ans[i]=find();
        i++;
    }
    for(int i=0;i<temp;i++){
        cout<<ans[i]<<endl;
    }
    return 0;
}

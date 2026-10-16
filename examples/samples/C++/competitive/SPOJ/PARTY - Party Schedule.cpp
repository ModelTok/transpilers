
#include <iostream>

using namespace std;
int max(int a, int b){
    if (a>=b) return a;
    else return b;
}
 
void display(int lis[], int n){
	for (int i=0 ; i<n ; ++i)
		cout<<lis[i]<<" ";
	cout<<endl;
}

int main(){
    int S,N,sum=0;
    cin>>S>>N;
    int siz[S+1],val[N+1],dp[N+1][S+1];
    int i=0;
    while(i<S+1)
	dp[0][i++] = 0;
    i=0;
    while(i<N+1)
	dp[i++][0] = 0;
    i=1;
    siz[0]=val[0]=0;
    while(i<N+1){
	cin>>siz[i]>>val[i];
	i++;
    }

    
    for(int i=1;i<N+1;++i){
	for(int j=1;j<S+1;++j){
	    if(j<siz[i]) dp[i][j] = dp[i-1][j];
	    else{
		dp[i][j] = max((val[i]+dp[i-1][j-siz[i]]),dp[i-1][j]);
	    }
	    
	    
	}
    }
    display(siz,N+1);
    display(val,N+1);
    
    for(int i=0;i<N+1;++i){
	for(int j=0;j<S+1;++j){
	    cout<<dp[i][j]<<" ";
	    }
	    cout<<endl;
	}
   
    cout<<sum<<" "<<dp[N][S]<<endl;
}

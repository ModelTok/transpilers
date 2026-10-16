

#include <bits/stdc++.h>
#define ll long long
using namespace std;
#define MAX 100001

vector<int>* sieve(){
    bool isPrime[100001];
    for(int i=0;i<MAX;i++){
         isPrime[i] = true;
    }
    for(int i=2;i*i<MAX;i++){
        if(isPrime[i]){
            for(int j=i*i;j<MAX;j+=i ){
                isPrime[j] = false;
            }
        }
    }
    vector<int>* primes = new vector<int>();
    primes->push_back(2);
    for(int i=3;i<MAX;i+=2){
        if(isPrime[i]){
            primes->push_back(i);
        }
    }
    return primes;
}

void printPrimes(ll l, ll r, vector<int>* & primes)
{
    bool isPrime[r-l+1];

    for(int i=0;i<=r-l;i++){
        isPrime[i] = true;

    }

    for(int i=0;primes->at(i)*(ll)primes->at(i)<=r;i++){
        int curPrime = primes->at(i);
        ll base = (l/(curPrime))*(curPrime);
        if(base<l){
            base = base + curPrime;
        }
        for(ll j=base;j<=r;j+=curPrime){
            isPrime[j-l] = false;
        }
        if(base==curPrime){
            isPrime[base-l]=true;
        }
    }
    for(int i=0;i<=r-l;i++){
        if(isPrime[i] == true){
            cout<< i + l<<endl;
        }
    }
}

int main()
{
    vector<int>* primes = sieve();
    int t;
    cin>>t;
    while(t--){
        ll l,r;
        cin>>l>>r;
        printPrimes(l,r,primes);
    }
    return 0;
}

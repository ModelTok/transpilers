
 
#include <iostream>

 
#include <bits/stdc++.h>

using namespace std;
#define pb push_back
#define intt long long
#define fori(n) for (ll i = 0; i < n; i++)
#define forj(n) for (ll j = 0; j < n; j++)
#define vl vector<ll> 
#define mod 1000000007
#define mp make_pair
#define vp vector<pair<int, int>>

 	int main()
 	{   
 	

 		intt n;
 		cin >> n;
 		intt a[n];

 		for (intt i = 0; i < n; i++)
 		{
 			cin >> a[i];
 		}

 		intt k;
 		cin >> k;
 		for (intt i = 0; i < k; i++)
 		{

 			intt x, y;
 			cin >> x >> y;
			
 			intt sum = 0;

 			for (intt i = x; i <= y; i++)
 			{
 				sum += a[i];
 			}
 			cout << sum << endl;
 		}

 		return 0;
 	}
	 
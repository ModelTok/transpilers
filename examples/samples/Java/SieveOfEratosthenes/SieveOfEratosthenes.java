
import java.util.*;
public class SieveOfEratosthenes {
	public static void main(String args[]) {
		int n = 100;
		
		Boolean[] isPrime = new Boolean[n];
		Arrays.fill(isPrime, Boolean.TRUE);
		
		for(int i = 2; i<n; i++) {
			if(isPrime[i-1]) {
				System.out.print(i + " "); 
				for(int j = i*i; j<=n; j+=i)
					isPrime[j-1] = false;
			}
		}
		
		
	}
}

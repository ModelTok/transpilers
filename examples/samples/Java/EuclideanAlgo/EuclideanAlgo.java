
import java.util.*;
public class EuclideanAlgo {
	public static void main(String args[]) {
		int a = 35, b = 10;
		System.out.println(gcd(a, b));
	}
	
	private static int gcd(int a, int b) {
		if(b <= 0)
			return a;
		
		return gcd(b, a%b);
	}
	
}

package Search;


import java.util.Scanner;


public class FibonacciSearch
{

	public static void main(String[] args)
	{

		int n;
		Scanner scanner = new Scanner(System.in);
		System.out.println("Enter the Number of Elements : ");
		n = scanner.nextInt();

		int inputArray[];
		inputArray = new int[n];
		System.out.println("Enter those "+ n + " Elements (in Ascending/Descending order) : ");
		for (int i=0; i<n; i++)
		{
			inputArray[i] = scanner.nextInt();
		}

		int search;
		System.out.println("Enter the number to search : ");
		search = scanner.nextInt();

		if(fibonacciSearch(inputArray, search) == -1)
		{
			System.out.println("OOPS ... Element "+ search + " is not found.");
		} else {
			System.out.println("Congrats :) ... Element "+ search + " is present at location "+ fibonacciSearch(inputArray, search));
		}
	}


	public static int fibonacciSearch(int[] array, int search){
		int fib_NMinus2 = 0;
		int fib_NMinus1 = 1;
		int fib_N = fib_NMinus2 + fib_NMinus1;

		while(fib_N < array.length)
		{
			fib_NMinus2 = fib_NMinus1;
			fib_NMinus1 = fib_N;
			fib_N = fib_NMinus2 + fib_NMinus1;
		}

		int offset = -1;

		while(fib_N > 1)
		{
			int i = minimum(offset + fib_NMinus2, array.length-1);

			if(array[i-1] < search)
			{
				fib_N = fib_NMinus1;
				fib_NMinus1 = fib_NMinus2;
				fib_NMinus2 = fib_N - fib_NMinus1;
				offset = i;
			} else if (array[i-1] > search)
			{
				fib_N = fib_NMinus2;
				fib_NMinus1 = fib_NMinus1 - fib_NMinus2;
				fib_NMinus2 = fib_N - fib_NMinus1;
			} else
			{
				return i;
			}
		}

		if (fib_NMinus1 == 1 && array[offset] == search)
		{
			return offset+1;
		}
		return -1;
	}

	public static int minimum(int x, int y)
	{
		return ((x <=y) ? x : y);
	}

}


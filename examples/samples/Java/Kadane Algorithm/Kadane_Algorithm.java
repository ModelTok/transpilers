
public class kadane_Algorithm
{
	public static int kadane(int input[], int n)
	{
		int current_max = 0;
		int max_so_far = 0;

		for(int i = 0; i < n; i++)
		{
			current_max = Math.max(0, current_max + input[i]);
			max_so_far = Math.max(max_so_far, current_max);
		}

		return max_so_far;
	}


	public static void main(String[] args)
	{
		int n, max_subarray_sum;
		int input[] = { -2, 1, -6, 4, -1, 2, 1, -5, 4 };
		n = input.length;

		int flag = 0;
		int largest_in_negative = input[0];

		for(int i = 0; i < n; i++)
		{
			if(input[i] >= 0)
			{
				flag = 1;
				break;
			}

			else if(input[i] > largest_in_negative)
				largest_in_negative = input[i];
		}

		if(flag == 1)
		     max_subarray_sum = kadane(input, n);
		else
		     max_subarray_sum = largest_in_negative;
		System.out.println("Maximum Subarray Sum is " + max_subarray_sum);
	}

}


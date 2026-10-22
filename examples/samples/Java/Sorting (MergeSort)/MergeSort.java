
import java.util.Arrays;

public class MergeSort {

	public static void mergeSort(float[] a)
	{
		float[] tmp = new float[a.length];
		mergeSort(a, tmp,  0,  a.length - 1);
	}

	private static void mergeSort(float [ ] a, float [ ] tmp, int left, int right)
	{
		if( left < right )
		{
			int center = (left + right) / 2;
			mergeSort(a, tmp, left, center);
			mergeSort(a, tmp, center + 1, right);
			merge(a, tmp, left, center + 1, right);
		}
	}

    private static void merge(float[ ] a, float[ ] tmp, int left, int right, int rightEnd )
    {	
        int leftEnd = right - 1;
        int k = left;
        int num = rightEnd - left + 1;

        while(left <= leftEnd && right <= rightEnd)
            if(a[left] <= a[right])
                tmp[k++] = a[left++];
            else
                tmp[k++] = a[right++];

        while(left <= leftEnd)
            tmp[k++] = a[left++];

        while(right <= rightEnd)
            tmp[k++] = a[right++];

        for(int i = 0; i < num; i++, rightEnd--)
            a[rightEnd] = tmp[rightEnd];
    }
    
    public static void main(String[] args) {
    	int NUM_ELEMENTS = 10;
    	float[] testArray = new float[NUM_ELEMENTS];
    	
    	System.out.println("Testing Array of floats");
    	for (int i = 0; i < testArray.length; i++) {
    		testArray[i] = (float) ( Math.random() * 10 );
    	}
    	
    	System.out.println("Before Sort: " + Arrays.toString(testArray));
    	mergeSort(testArray);
    	System.out.println("After Sort: " + Arrays.toString(testArray));
    }
}


import java.util.*;

public class RadixSort {

    private static void radixsort(int arr[], int a) {
        int max = arr[0];
        for (int i = 0; i < a; i++) {
            if (arr[i] > max)
                max = arr[i];
        }

        for (int j = 1; max / j > 0; j *= 10)
            countSort(arr, a, j);
    }

    private static void countSort(int arr[], int a, int j) {
        int result[] = new int[a];
        int i;
        int count[] = new int[10];
        Arrays.fill(count, 0);

        for (i = 0; i < a; i++)
            count[(arr[i] / j) % 10]++;

        for (i = 1; i < 10; i++)
            count[i] += count[i - 1];

        for (i = a - 1; i >= 0; i--) {
            result[count[(arr[i] / j) % 10] - 1] = arr[i];
            count[(arr[i] / j) % 10]--;
        }

        for (i = 0; i < a; i++)
            arr[i] = result[i];
    }

    public static void main(String[] args) {
        int arr[] = { 20, 399, 70, 9, 78, 80, 32, 500, 499 };
        int a = arr.length;
        System.out.println("Testing Radix Sort");
        System.out.println("Before Sort: " + Arrays.toString(arr));
        radixsort(arr, a);
        System.out.println("After Sort: " + Arrays.toString(arr));
    }
}



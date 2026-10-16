
public class RecursiveInsertionSort {

    public Integer[] sort(Integer[] array, boolean optimize) {
        return optimize ? optimizedSort(array, array.length - 1) : sort(array, array.length - 1);
    }

    private Integer[] sort(Integer[] array, int n) {
        if (n > 0) {

            sort(array, n - 1);

            int j = n;
            while (j > 0 && array[j - 1] > array[j]) {

                int temp = array[j - 1];
                array[j - 1] = array[j];
                array[j] = temp;

                j = j - 1;
            }
        }
        return array;
    }

    private Integer[] optimizedSort(Integer[] array, int n) {
        if (n > 0) {

            optimizedSort(array, n - 1);

            int x = array[n];
            int j = n - 1;
            while (j >= 0 && array[j] > x) {
                array[j + 1] = array[j];
                j = j - 1;
            }
            array[j + 1] = x;
        }
        return array;
    }

}

public class InsertionSort {

    public Integer[] sort(Integer[] array, boolean optimize) {
        return optimize ? optimizedSort(array) : sort(array);
    }

    private Integer[] sort(Integer[] array) {
        int i = 1;
        while (i < array.length) {
            int j = i;
            while (j > 0 && array[j - 1] > array[j]) {

                int temp = array[j - 1];
                array[j - 1] = array[j];
                array[j] = temp;

                j = j - 1;
            }
            i = i + 1;
        }
        return array;
    }

    private Integer[] optimizedSort(Integer[] array) {
        int i = 1;
        while (i < array.length) {
            int x = array[i];
            int j = i - 1;
            while (j >= 0 && array[j] > x) {
                array[j + 1] = array[j];
                j = j - 1;
            }
            array[j + 1] = x;
            i = i + 1;
        }
        return array;
    }

}
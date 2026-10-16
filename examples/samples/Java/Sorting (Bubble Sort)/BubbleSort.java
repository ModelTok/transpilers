
public class BubbleSort {

    public Integer[] sort(Integer[] array, boolean optimize) {
        return optimize ? optimizedSort(array) : sort(array);
    }

    private Integer[] sort(Integer[] array) {
        boolean isSwapped;
        int n = array.length;
        do {
            isSwapped = false;
            for (int index = 0; index < n - 1; index++) {
                if (array[index] > array[index + 1]) {

                    int temp = array[index];
                    array[index] = array[index + 1];
                    array[index + 1] = temp;

                    isSwapped = true;
                }
            }
        } while (isSwapped);
        return array;
    }

    private Integer[] optimizedSort(Integer[] array) {
        boolean isSwapped;
        int n = array.length;
        do {
            isSwapped = false;
            for (int index = 0; index < n - 1; index++) {
                if (array[index] > array[index + 1]) {

                    int temp = array[index];
                    array[index] = array[index + 1];
                    array[index + 1] = temp;

                    isSwapped = true;
                }
            }
            n = n - 1;
        } while (isSwapped);
        return array;
    }

}
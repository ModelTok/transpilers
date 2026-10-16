
import java.util.stream.IntStream;

public class SelectionSort {

    public Integer[] sort(Integer[] array) {

        IntStream.range(0, array.length - 1).forEach(j -> {

            int iMin = IntStream.range(j + 1, array.length)
                    .reduce(j, (left, right) -> array[right] < array[left] ? right : left);

            if (iMin != j) {

                int temp = array[iMin];
                array[iMin] = array[j];
                array[j] = temp;

            }

        });

        return array;
    }

}
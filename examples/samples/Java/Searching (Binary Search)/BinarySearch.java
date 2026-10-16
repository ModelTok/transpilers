
import java.util.Optional;

public class BinarySearch {

    public Optional<Integer> search(Integer[] array, Integer key) {

        int start = 0;
        int end = array.length - 1;

        while (start <= end) {

            int middle = start + (end - start) / 2;

            if (key < array[middle]) {
                end = middle - 1;
            } else if (key.equals(array[middle])) {
                return Optional.of(middle);
            } else {
                start = middle + 1;
            }

        }

        return Optional.empty();

    }

}

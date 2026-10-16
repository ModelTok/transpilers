
import java.util.Optional;

public class RecursiveBinarySearch {

    public Optional<Integer> search(Integer[] array, Integer key) {
        return recurse(array, key, 0, array.length - 1);
    }

    private Optional<Integer> recurse(Integer[] array, Integer key, Integer start, Integer end) {

        if (start <= end) {

            int middle = start + (end - start) / 2;

            if (key < array[middle]) {
                return recurse(array, key, start, middle - 1);
            } else if (key.equals(array[middle])) {
                return Optional.of(middle);
            } else {
                return recurse(array, key, middle + 1, end);
            }

        } else {
            return Optional.empty();
        }

    }

}


import java.util.Optional;

public class RecursiveLinearSearch {

    public Optional<Integer> search(Integer[] array, Integer key) {
        return recurse(array, key, 0);
    }

    private Optional<Integer> recurse(Integer[] array, Integer key, Integer index) {

        if (key.equals(array[index])) {
            return Optional.of(index);
        } else if (index < array.length - 1) {
            return recurse(array, key, index + 1);
        } else {
            return Optional.empty();
        }

    }

}
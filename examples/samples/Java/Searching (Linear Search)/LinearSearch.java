
import java.util.Optional;

public class LinearSearch {

    public Optional<Integer> search(Integer[] array, Integer key) {
        for (int index = 0; index < array.length; index++) {
            if (key.equals(array[index])) {
                return Optional.of(index);
            }
        }
        return Optional.empty();
    }

}

import java.util.Collection;

public class SequenceMinimum {

    public Integer minimum(Collection<Integer> sequence) {
        return sequence.stream().reduce(Integer.MAX_VALUE, Integer::min);
    }

}

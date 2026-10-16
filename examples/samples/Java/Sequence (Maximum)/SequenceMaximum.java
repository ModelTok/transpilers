
import java.util.Collection;

public class SequenceMaximum {

    public Integer maximum(Collection<Integer> sequence) {
        return sequence.stream().reduce(Integer.MIN_VALUE, Integer::max);
    }

}

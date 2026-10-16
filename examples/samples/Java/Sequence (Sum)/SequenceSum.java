
import java.util.Collection;

public class SequenceSum {

    public Integer sum(Collection<Integer> sequence) {
        return sequence.stream().reduce(0, Integer::sum);
    }

}

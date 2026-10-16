
import java.util.Collection;

public class SequenceMean {

    public Double mean(Collection<Integer> sequence) {
        return (double) sequence.stream().reduce(0, Integer::sum) / sequence.size();
    }

}


import java.util.Collection;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

public class QuickFind<T> {

    private int count;
    private Map<T, T> identifiers;

    public QuickFind(Collection<T> components) {
        count = components.size();
        identifiers = components.stream().collect(Collectors.toMap(Function.identity(), Function.identity()));
    }

    public void union(T t1, T t2) {

        if(!identifiers.containsKey(t1) || !identifiers.containsKey(t2)) {
            throw new IllegalStateException();
        }

        T t1Id = identifiers.get(t1);
        T t2Id = identifiers.get(t2);

        if(t1Id.equals(t2Id)) {
            return;
        }

        identifiers = identifiers.entrySet().stream().map(e -> {
            if(e.getValue().equals(t1Id)) {
                e.setValue(t2Id);
            }
            return e;
        }).collect(Collectors.toMap(Map.Entry::getKey,Map.Entry::getValue));

        count--;

    }

    public T find(T t) {

        if(!identifiers.containsKey(t)) {
            throw new IllegalStateException();
        }

        return identifiers.get(t);
    }

    public boolean connected(T t1, T t2) {

        if(!identifiers.containsKey(t1) || !identifiers.containsKey(t2)) {
            throw new IllegalStateException();
        }

        return identifiers.get(t1).equals(identifiers.get(t2));
    }

    public int count() {
        return count;
    }

}
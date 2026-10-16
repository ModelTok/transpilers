
import java.util.*;

public class DirectedGraph<V> {

    private final Map<V, Set<V>> adjacencyList;

    public DirectedGraph() {
        this.adjacencyList = new HashMap<>();
    }

    public Map<V, Set<V>> adjacencyList() {
        return adjacencyList;
    }

    public boolean adjacent(V source, V target) {
        return adjacencyList.containsKey(source) && adjacencyList.get(source).contains(target);
    }

    public Set<V> neighbours(V vertex) {
        if (adjacencyList.containsKey(vertex)) {
            return adjacencyList.get(vertex);
        } else {
            throw new IllegalStateException("Vertex not found in the Graph.");
        }
    }

    public void addVertex(V vertex) {
        adjacencyList.putIfAbsent(vertex, new HashSet<>());
    }

    public void removeVertex(V vertex) {
        if (adjacencyList.containsKey(vertex)) {
            adjacencyList.remove(vertex);
            adjacencyList.values().forEach(neighbours -> neighbours.remove(vertex));
        }
    }

    public void addEdge(V source, V target) {
        if (adjacencyList.containsKey(source) && adjacencyList.containsKey(target)) {
            adjacencyList.get(source).add(target);
        } else {
            throw new IllegalStateException("Vertex not found in the Graph.");
        }
    }

    public void removeEdge(V source, V target) {
        if (adjacencyList.containsKey(source)) {
            adjacencyList.get(source).remove(target);
        }
    }

}
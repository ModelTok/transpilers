
import java.util.*;

public class TopologicalSort<V> {

    public List<V> topologicalSort(DirectedGraph<V> graph) {

        final LinkedList<V> sorted = new LinkedList<>();
        final Map<V, VertexStatus> statusMap = new HashMap<>();

        graph.adjacencyList().keySet().forEach(v -> recurse(graph, v, sorted, statusMap));

        return sorted;

    }

    private void recurse(DirectedGraph<V> graph, V vertex, LinkedList<V> sorted, Map<V, VertexStatus> statusMap) {

        VertexStatus vertexStatus = statusMap.getOrDefault(vertex, VertexStatus.NOT_MARKED);

        if (vertexStatus.equals(VertexStatus.PERMANENTLY_MARKED)) {
            return;
        }

        if (vertexStatus.equals(VertexStatus.TEMPORARILY_MARKED)) {
            throw new IllegalStateException("Grapg has atleast 1 cycle.");
        }

        statusMap.put(vertex, VertexStatus.TEMPORARILY_MARKED);
        graph.adjacencyList().get(vertex).forEach(v -> recurse(graph, v, sorted, statusMap));
        statusMap.put(vertex, VertexStatus.PERMANENTLY_MARKED);
        sorted.push(vertex);

    }

}

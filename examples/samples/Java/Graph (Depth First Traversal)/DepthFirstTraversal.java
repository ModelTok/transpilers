
import java.util.*;

public class DepthFirstTraversal<V> {

    public void depthFirstTraversal(DirectedGraph<V> graph, V vertex) {

        final Set<V> visited = new HashSet<>();
        recurse(graph, vertex, visited);

    }

    private void recurse(DirectedGraph<V> graph, V vertex, Set<V> visited) {

        visited.add(vertex);

        graph.adjacencyList().get(vertex).forEach(v -> {
            if (!visited.contains(v)) {
                recurse(graph, v, visited);
            }
        });

    }

}
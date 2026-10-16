
import java.util.HashSet;
import java.util.PriorityQueue;
import java.util.Queue;
import java.util.Set;

public class BreadthFirstTraversal<V> {

    public void breadthFirstTraversal(DirectedGraph<V> graph, V vertex) {

        final Set<V> visited = new HashSet<>();
        final Queue<V> queue = new PriorityQueue<>();

        queue.add(vertex);
        visited.add(vertex);

        while (!queue.isEmpty()) {

            V s = queue.remove();

            graph.adjacencyList().get(s).forEach(v -> {
                if (!visited.contains(v)) {
                    visited.add(v);
                    queue.add(v);
                }
            });

        }

    }

}
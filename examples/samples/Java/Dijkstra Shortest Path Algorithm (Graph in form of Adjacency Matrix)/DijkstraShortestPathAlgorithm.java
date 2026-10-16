
import java.util.Scanner;


public class DijkstraShortestPathAlgorithm {
	
	public static void main(String args []){
		
		int vertices;
		Scanner scanner = new Scanner (System.in);
		System.out.println("Enter the number of vertices present in graph :- ");
		vertices = scanner.nextInt();
		
		int adjacencyMatrix[][] = new int[vertices][vertices];
		System.out.println("Enter the Adjacency Matrix of the graph (Distance between adjacent vertices of the graph) :- ");
		for (int i=0; i<vertices; i++){
			for (int j=0; j<vertices; j++){
				adjacencyMatrix[i][j] = scanner.nextInt();
			}
		}
		
		System.out.println("Printing Graph in the form of Adjacency Matrix :- ");
		for (int i=0; i<vertices; i++){
			for (int j=0; j<vertices; j++){
				System.out.print(adjacencyMatrix[i][j]+" ");
			}
			System.out.println("");
		}
		
		System.out.println("");
		
		dijkstraShortestPath(adjacencyMatrix, vertices, 0);
		
	}

	private static void dijkstraShortestPath(int[][] graph, int numberOfVertices, int sourceVertex) {
		
		int shortestDistance[] = new int[numberOfVertices];
		
		Boolean verticesTrackingStatus[] = new Boolean[numberOfVertices];
		
		for (int i=0; i<numberOfVertices; i++){
			shortestDistance[i] = Integer.MAX_VALUE;
		}
		
		for (int i=0; i<numberOfVertices; i++){
			verticesTrackingStatus[i] = false;
		}
		
		shortestDistance[sourceVertex]=0;
		
		for (int i=0; i<numberOfVertices-1; i++){
			int finalPickedVertex = minimumDistance(shortestDistance, verticesTrackingStatus, numberOfVertices);
			
			verticesTrackingStatus[finalPickedVertex] = true;
			
			for (int j=0; j<6; j++){
				if (!verticesTrackingStatus[j]
						&& graph[finalPickedVertex][j] != 0
						&& shortestDistance[finalPickedVertex] != Integer.MAX_VALUE
						&& shortestDistance[finalPickedVertex] + graph[finalPickedVertex][j] < shortestDistance[j]){
					shortestDistance[j] = shortestDistance[finalPickedVertex] + graph[finalPickedVertex][j];
				}
			}
		}
		
		printShortestDistance(shortestDistance, numberOfVertices);
	}

	
	
	private static int minimumDistance(int[] shortestDistance, Boolean[] verticesTrackingStatus, int numberOfVertices) {
		int minimum = Integer.MAX_VALUE;
		int minimumIndex = -1;
		
		for(int i=0; i<numberOfVertices; i++){
			if (verticesTrackingStatus[i] == false && shortestDistance[i] <= minimum){
				minimum = shortestDistance[i];
				minimumIndex = i;
			}
		}
		return minimumIndex;
	}
	

	
	private static void printShortestDistance(int[] shortestDistance, int numberOfVertices) {
		System.out.println("Vertex \t\t Distance From Source Vertex");
		for (int i=0; i<numberOfVertices; i++){
			System.out.println(i + "\t\t" + shortestDistance[i]);
		}
		
	}
}


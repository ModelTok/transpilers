
import java.util.*;
public class BinaryTreeBFS {
	static class Node{
		int data;
		Node left,right;
		Node(int data){
			this.data=data;
			left=right=null;
		}
	}
	static Node root;
	static Node temp=root;
	public static void bfs(Node temp) {
		if(temp==null) {
			return;
		}
		Queue<Node> q=new LinkedList<Node>();
		List<Integer>l=new ArrayList<Integer>();
		q.add(temp);
		Node temp2;
		while(!q.isEmpty()) {
			temp2=q.poll();
			l.add(temp2.data);
			if(temp2.left!=null) {
				q.add(temp2.left);
			}
			if(temp2.right!=null) {
				q.add(temp2.right);
			}
		}
		System.out.println("Level Order is: "+l);
	}
	public static void main(String[] args) {
		temp=new Node(1);
		temp.left=new Node(2);
		temp.right=new Node(3);
		temp.left.left=new Node(4);
		temp.left.right=new Node(5);
		bfs(temp);
	}
}

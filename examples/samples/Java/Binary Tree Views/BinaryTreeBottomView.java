import java.util.*;
import java.util.Map.Entry;
class Node{
	int data;
	int hd;
	Node left,right;
	Node(int data){
		this.data=data;
		hd=Integer.MAX_VALUE;
		left=right=null;
	}
}
class BinaryTreeBottomView {
	Node root;
	public BinaryTreeBottomView() {}
	public BinaryTreeBottomView(Node node) {
		root=node;
	}
	public void getBottomView() {
		if(root==null)
			return ;
		int hd=0;
		Map<Integer,Integer>map=new TreeMap<>();
		Queue<Node> queue=new LinkedList<Node>();
		root.hd=hd;
		queue.add(root);
		while(!queue.isEmpty()) {
			Node temp=queue.remove();
			hd=temp.hd;
			map.put(hd,temp.data);
			if(temp.left!=null) {
				temp.left.hd=hd-1;
				queue.add(temp.left);
			}
			if(temp.right!=null) {
				temp.right.hd=hd+1;
				queue.add(temp.right);
			}
		}
		Set<Entry<Integer,Integer>> set=map.entrySet();
		Iterator<Entry<Integer,Integer>> it=set.iterator();
		while(it.hasNext()) {
			Map.Entry<Integer,Integer> me=it.next();
			System.out.print(me.getValue()+" ");
		}
	}
	public static void main(String args[]) {
		Scanner sc=new Scanner(System.in);
		Node root=new Node(1);
		root.left=new Node(2);
		root.right=new Node(3);
		root.right.left=new Node(5);
		root.right.right=new Node(6);
		root.right.left.left=new Node(7);
		root.right.left.right=new Node(8);
		BinaryTreeBottomView b=new BinaryTreeBottomView(root);
		System.out.println("Bottom view of the binary tree: ");
		b.getBottomView();
	}
}

import java.util.*;
public class BinaryTreeRightView {
	public static void rightView(BinaryNode root) {
		if(root==null)
			return ;
		Queue<BinaryNode> q =new LinkedList<>();
		q.add(root);
		int i,n;
		BinaryNode temp;
		while(!q.isEmpty()) {
			n=q.size();
			for(i=1;i<=n;i++) {
				temp=q.poll();
				if(i==n)
					System.out.print(temp.data+" ");
				if(temp.left!=null)
					q.add(temp.left);
				if(temp.right!=null)
					q.add(temp.right);
			}
		}
	}
	public static void main(String[] args) {
		BinaryNode root = new  BinaryNode(10); 
		root.left = new  BinaryNode(2); 
		root.right = new  BinaryNode(3); 
		root.left.left = new  BinaryNode(7); 
		root.left.right = new  BinaryNode(8); 
		root.right.right = new  BinaryNode(15); 
		root.right.left = new BinaryNode(12); 
		root.right.right.left = new  BinaryNode(14); 
		System.out.println("Right view of the binary tree: ");
		rightView(root);
	}

}

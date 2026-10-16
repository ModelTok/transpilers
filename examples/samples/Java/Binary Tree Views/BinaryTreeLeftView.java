import java.util.*;
public class BinaryTreeLeftView {
	public static int leftview(BinaryNode root,int currlevel,int lastlevel) {
		if(root==null)
			return lastlevel;
		if(currlevel>lastlevel) {
			System.out.print(root.data+" ");
			lastlevel=currlevel;
		}
		lastlevel=leftview(root.left,currlevel+1,lastlevel);
		lastlevel=leftview(root.right,currlevel+1,lastlevel);
		return lastlevel;
	}
	public static void leftview(BinaryNode root) {
		leftview(root,1,0);
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
		System.out.println("Left view of the binary tree: ");
		leftview(root);
	}

}

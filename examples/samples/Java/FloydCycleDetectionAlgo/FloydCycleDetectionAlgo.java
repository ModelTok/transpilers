
import java.util.*;
public class FloydCycleDetectionAlgo {
	public static void main(String args[]) {		
		ListNode head = new ListNode(1);
		ListNode currNode = head;
		currNode.next = new ListNode(2);
		currNode = currNode.next;
		currNode.next = new ListNode(3);
		currNode = currNode.next;
		currNode.next = new ListNode(4);
		currNode = currNode.next;
		currNode.next = new ListNode(5);
		currNode = currNode.next;
		currNode.next = new ListNode(6);
		currNode = currNode.next;
		currNode.next = new ListNode(7);
		currNode = currNode.next;
		currNode.next = new ListNode(8);
		currNode = currNode.next;
		
		currNode.next = head.next.next;
		
		
		 System.out.println(detectCycle(head).val);
	}
	
	public static ListNode detectCycle(ListNode head) {
		ListNode slow = head;
		ListNode fast = head;
		while(fast.next != null && fast.next.next!=null) {
			slow = slow.next;
			fast = fast.next.next;
			if(fast == slow) {
				slow = head;
				while(slow != fast) {
					slow = slow.next;
					fast = fast.next;
				}
				return slow;
			}
		}
		return null;
    }
}

class ListNode {
	int val;
	ListNode next;
	ListNode(int x) {
	val = x;
	next = null;
	}
}

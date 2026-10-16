
import java.util.Arrays;
class HeapSort {
  public static void main(String[] args) {
    int a[] ={8,9,2,5,6,1};
    heapSort(a);
    System.out.println(Arrays.toString(a));
  }
  static void heapSort(int a[]) 
    { 
        int n = a.length; 
  
        for (int i = n / 2 - 1; i >= 0; i--) {
            heapify(a, n, i);
        }
        for (int i=n-1; i>0; i--) 
        { 
            int temp = a[0]; 
            a[0] = a[i]; 
            a[i] = temp; 
            heapify(a, i, 0); 
        } 
    } 
    static void heapify(int a[], int n, int parent) 
    { 
        int largest = parent;
        int left_child = 2*parent + 1;
        int right_child = 2*parent + 2;
  
        if (left_child < n && a[left_child] > a[largest]) 
            largest = left_child; 
  
        if (right_child < n && a[right_child] > a[largest]) 
            largest = right_child; 
  
        if (largest != parent) 
        { 
            int swap = a[parent]; 
            a[parent] = a[largest]; 
            a[largest] = swap; 
  
            heapify(a, n, largest); 
        } 
    } 
}
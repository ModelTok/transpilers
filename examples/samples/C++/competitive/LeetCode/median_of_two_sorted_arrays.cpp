
double findMedianSortedArrays(vector<int>& nums1, vector<int>& nums2) {
        
    if(nums1.size() > nums2.size())
        return findMedianSortedArrays(nums2,nums1);
        
    int x=nums1.size(), y=nums2.size();
    int low=0, high=x;
        
    while(low <= high){
        int partition_x = (low+high)/2;
        int partition_y = ((x+y+1)/2) - partition_x;
        int maxleft_x = (partition_x == 0) ? INT_MIN : (nums1[partition_x-1]);
        int minright_x = (partition_x == x) ? INT_MAX : (nums1[partition_x]);
            
        int maxleft_y = (partition_y == 0) ? INT_MIN : (nums2[partition_y-1]);
        int minright_y=(partition_y == y) ? INT_MAX : (nums2[partition_y]);
            
        if(maxleft_x <= minright_y && maxleft_y <= minright_x){
            if(((x+y) % 2) == 0)
                return (double)(max(maxleft_x, maxleft_y) + min(minright_x, minright_y))/2;
            else 
                return (double) max(maxleft_x, maxleft_y);
        }
        else if(maxleft_x < minright_y)
            low = partition_x + 1;
        else 
            high = partition_x - 1;

    }
    return -1;
}

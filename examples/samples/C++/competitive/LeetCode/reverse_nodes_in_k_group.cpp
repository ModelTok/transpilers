
ListNode* rev(ListNode* head){
    if((!head) || (!head->next))
        return head;
    ListNode* prev=NULL, *curr = head, *next = head->next;
    while(next){
        ListNode* temp = next->next;
        curr->next = prev;
        next->next = curr;
        prev = curr;
        curr = next;
        next = temp;
    }
    return curr;
}

ListNode* reverseKGroup(ListNode* head, int k) {
    int i = 0, len = 0;
    ListNode* ans = new ListNode(0);
    ans->next = head;
    ListNode *temp2 = head;
        
    while(temp2){
        temp2 = temp2->next;
        len++;
    }
        
    temp2 = ans;
    while(i < len){
        int j=i;
        ListNode* old = temp2;
        while((temp2) && (j <= (i+k-1)) && (j <= len)){
            temp2 = temp2->next;
            j++;
        }
        if((!temp2) || (j > len) && ((j-i) < k)){
            break;
        }
        ListNode *temp1 = temp2->next;
        temp2->next = NULL;
        ListNode *temp4 = old->next;
        old->next = rev(temp4);
        while(old->next){
            old = old->next;
        }
        temp2 = old;
        old->next = temp1;
        i = j;
    }
    
    return ans->next;
}

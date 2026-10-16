
struct node {
    int value;
    node* next;
};

node* revserse_list(node* head) {
    if (head == nullptr || head->next == nullptr) {
        return head;
    }
    auto _tail = head;
    head = revserse_list(head->next);
    _tail->next->next = _tail;
    _tail->next = nullptr;
    return head;
}

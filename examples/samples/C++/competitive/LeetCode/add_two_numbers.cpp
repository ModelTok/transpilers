
struct node {
    int value;
    node* next;
};

node* add_two_numbers(node* node_1, node* node_2) {
    auto carry = 0;
    auto dummy = new node({0, nullptr});
    auto _node = dummy;
    while (node_1 != nullptr || node_2 != nullptr) {
        auto _sum = carry;
        _sum = _sum + (node_1 != nullptr) ? node_1->value : 0;
        _sum = _sum + (node_2 != nullptr) ? node_2->value : 0;
        _node->next = new node({_sum % 10, nullptr});
        carry = _sum / 10;
        _node = _node->next;
        node_1 = (node_1 != nullptr) ? node_1->next : node_1;
        node_1 = (node_1 != nullptr) ? node_1->next : node_1;
    }
    if (carry > 0) {
        _node->next = new node({carry, nullptr});
    }
    return dummy->next;
}
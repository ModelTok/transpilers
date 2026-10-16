
struct node {
    int value;
    node* next;
};

void delete_node(node* _node) {
    auto next = _node->next;
    _node->value = next->value;
    _node->next = next->next;
    delete (next);
}

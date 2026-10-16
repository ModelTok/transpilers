
struct node {
    int value;
    node* next;
    node* random;
};

node* copy_random_list(node* head) {

    auto original_node = head;
    while (original_node != nullptr) {
        auto copy_node = new node(*original_node);
        original_node->next = copy_node;
        original_node = copy_node->next;
    }

    original_node = head;
    while (original_node != nullptr) {
        if (original_node->random != nullptr) {
            original_node->next->random = original_node->random->next;
        }
        original_node = original_node->next->next;
    }

    original_node = head;
    auto copy_head = head->next;
    auto copy_node = copy_head;
    while (original_node != nullptr) {
        original_node->next = original_node->next->next;
        original_node = original_node->next;
        if (original_node != nullptr) {
            copy_node->next = copy_node->next->next;
            copy_node = copy_node->next;
        }
    }

    return copy_head;
}

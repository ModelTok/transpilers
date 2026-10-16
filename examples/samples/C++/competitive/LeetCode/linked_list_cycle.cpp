
struct node {
    int value;
    node* next;
};

bool has_cycle(node* head) {
    auto tortoise = head;
    auto hare = head;
    while (hare != nullptr) {
        tortoise = tortoise->next;
        hare = hare->next;
        if (hare == nullptr) {
            break;
        }
        hare = hare->next;
        if (tortoise == hare) {
            return true;
        }
    }
    return false;
}

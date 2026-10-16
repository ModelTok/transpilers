
#include <algorithm>

struct node {
    int data;
    node* left;
    node* right;
};

int maximum_depth(node* root) {
    if (root == nullptr) {
        return 0;
    }
    return 1 + std::max(maximum_depth(root->left), maximum_depth(root->right));
}

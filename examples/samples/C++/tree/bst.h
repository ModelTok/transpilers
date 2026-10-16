
#ifndef MEHARA_BST_H_
#define MEHARA_BST_H_

namespace mehara::tree {

template <typename Node, typename Key>
class bst {
  public:
    Node* search(Key key)
    {
        Node* node = root;
        while (node != nullptr && key != node->key) {
            if (key < node->key) {
                node = node->left;
            }
            else {
                node = node->right;
            }
        }
        return node;
    }

    Node* maximum()
    {
        Node* node = root;
        while (node->right != nullptr) {
            node = node->right;
        }
        return node;
    }

    Node* minimum()
    {
        Node* node = root;
        while (node->left != nullptr) {
            node = node->left;
        }
        return node;
    }

    Node* predecessor(Node* node)
    {
        if (node->left != nullptr) {
            return node->left;
        }
        Node* _predecessor = node->parent;
        Node* _node = new Node(node);
        while (_predecessor != nullptr && _node == _predecessor->left) {
            _node = _predecessor;
            _predecessor = _predecessor->parent;
        }
        return _predecessor;
    }

    Node* successor(Node* node)
    {
        if (node->right != nullptr) {
            return node->right;
        }
        Node* _successor = node->parent;
        Node* _node = new Node(node);
        while (_successor != nullptr && _node == _successor->right) {
            _node = _successor;
            _successor = _successor->parent;
        }
        return _successor;
    }

  private:
    Node* root;
};

}

#endif

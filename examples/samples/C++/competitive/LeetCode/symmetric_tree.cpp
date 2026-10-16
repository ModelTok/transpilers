
class Solution {
public:
    bool check(TreeNode* a, TreeNode* b){
        if(a == NULL && b == NULL){
            return true;
        }
        if(a == NULL || b == NULL){
            return false;
        }
        if(a->val == b->val){
           return check(a->left,b->right) && check(a->right,b->left);
        }
        return false;
    }
    bool isSymmetric(TreeNode* root) {
        return check(root,root);
        
    }
};
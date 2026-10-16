
class Solution {
public:
    bool isSameTree(TreeNode* p, TreeNode* q) {
        if(!p&&!q) return true;
        if((!p&&q)||(p&&!q)) return false;
        bool vals = (p->val == q->val);
        bool left = isSameTree(p->left,q->left);
        bool right = isSameTree(p->right,q->right);
        
        return (vals && left && right);
    }
};
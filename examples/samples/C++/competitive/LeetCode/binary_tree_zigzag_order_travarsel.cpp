
class Solution {
public:
    void levelOrder(int depth, TreeNode* root, vector<vector<int>> &ans){
        if(!root)
            return;
        if(ans.size()==depth){
            ans.push_back(vector<int>());
        }
        if(depth%2==0){
            ans[depth].push_back(root->val);
        }else{
            ans[depth].insert(ans[depth].begin(), root->val);   
        }
        
        levelOrder(depth+1, root->left, ans);
        levelOrder(depth+1, root->right, ans);
    }
    
    vector<vector<int>> zigzagLevelOrder(TreeNode* root) {
        vector<vector<int>> ans;
        levelOrder(0, root, ans);
        return ans;
    }
};
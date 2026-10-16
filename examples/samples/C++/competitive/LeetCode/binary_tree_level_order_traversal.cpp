
class Solution {
public:
    map<int,vector<int>> v;
    
    void dfs(TreeNode* root, int h){
        if(!root) return;
        if(root->left==NULL && root->right==NULL){
            v[h].push_back(root->val);
            return;
        }
        v[h].push_back(root->val);
        dfs(root->left, h+1);
        dfs(root->right, h+1);
    }
    
    vector<vector<int>> levelOrder(TreeNode* root) {
        vector<vector<int>> ans;
        if(!root) return ans;
        dfs(root,1);
        for(auto i:v){
            ans.push_back(i.second);
        }
        return ans;
    }
};
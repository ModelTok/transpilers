
#include <stack>
#include <string>

bool is_valid(const std::string& parentheses) {
    std::stack<char> parenthesis_stack;
    for (const auto& parenthesis : parentheses) {
        if (parenthesis == '(' || parenthesis == '{' || parenthesis == '[') {
            parenthesis_stack.push(parenthesis);
        } else {
            if (parenthesis_stack.empty() ||
                (parenthesis_stack.top() != '(' && parenthesis == ')') ||
                (parenthesis_stack.top() != '{' && parenthesis == '}') ||
                (parenthesis_stack.top() != '[' && parenthesis == ']')) {
                return false;
            }
            parenthesis_stack.pop();
        }
    }
    return parenthesis_stack.empty();
}
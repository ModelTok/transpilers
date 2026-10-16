
#include <stack>
#include <string>
#include <vector>

int evaluate_reverse_polish_notation(const std::vector<std::string>& tokens) {
    std::stack<int> operand_stack;
    for (const auto& token : tokens) {
        if (token == "+" || token == "-" || token == "*" || token == "/") {
            int second_operand = operand_stack.top();
            operand_stack.pop();
            int first_operand = operand_stack.top();
            operand_stack.pop();
            if (token == "+") {
                operand_stack.push(first_operand + second_operand);
            } else if (token == "-") {
                operand_stack.push(first_operand - second_operand);
            } else if (token == "*") {
                operand_stack.push(first_operand * second_operand);
            } else {
                operand_stack.push(first_operand / second_operand);
            }
        } else {
            operand_stack.push(std::stoi(token));
        }
    }
    return operand_stack.top();
}
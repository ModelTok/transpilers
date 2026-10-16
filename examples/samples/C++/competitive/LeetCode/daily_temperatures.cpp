
#include <stack>
#include <vector>

std::vector<int> daily_temperatures(const std::vector<int>& temperatures)
{
    std::vector<int> wait(temperatures.size());
    std::stack<int> _stack;
    for (int i = temperatures.size() - 1; i >= 0; i--) {
        while (!_stack.empty() &&
               temperatures[i] >= temperatures[_stack.top()]) {
            _stack.pop();
        }
        wait[i] = _stack.empty() ? 0 : _stack.top() - i;
        _stack.push(i);
    }
    return wait;
}
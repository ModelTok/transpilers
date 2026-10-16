
#include <functional>
#include <queue>
#include <unordered_map>
#include <vector>

std::vector<int> top_k_frequent_elements(const std::vector<int>& numbers,
                                         int k) {
    std::unordered_map<int, int> frequency_map;
    for (const auto& number : numbers) {
        frequency_map[number]++;
    }

    auto _comp = [](const std::pair<int, int>& x,
                    const std::pair<int, int>& y) {
        return x.second > y.second;
    };
    std::priority_queue<int, std::vector<std::pair<int, int>>, decltype(_comp)>
        _priority_queue(_comp);

    for (const auto& _pair : frequency_map) {
        _priority_queue.push(_pair);
        if (_priority_queue.size() > k) {
            _priority_queue.pop();
        }
    }

    std::vector<int> frequent_elements(k);
    while (k > 0) {
        frequent_elements[--k] = _priority_queue.top().first;
        _priority_queue.pop();
    }
    return frequent_elements;
}

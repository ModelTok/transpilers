
#include <stack>
#include <tuple>
#include <vector>

class nested_integer {
  public:
    bool is_integer() const;

    int get_integer() const;

    const std::vector<nested_integer>& get_list() const;
};

class nested_iterator {
  public:
    nested_iterator(const std::vector<nested_integer>& nested_list) {
        stack_.emplace(nested_list.begin(), nested_list.end());
    }

    int next() {
        auto& [it, end] = stack_.top();
        auto _next = it->get_integer();
        it++;
        return _next;
    }

    bool has_next() {
        while (!stack_.empty()) {
            auto& [it, end] = stack_.top();
            if (it == end) {
                stack_.pop();
                if (!stack_.empty()) {
                    auto& [it, end] = stack_.top();
                    it++;
                }
            } else if (it->is_integer()) {
                return true;
            } else {
                stack_.emplace(it->get_list().begin(), it->get_list().end());
            }
        }
        return false;
    }

  private:
    std::stack<std::tuple<std::vector<nested_integer>::iterator,
                          std::vector<nested_integer>::iterator>>
        stack_;
};
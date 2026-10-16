
#include <list>
#include <unordered_map>
#include <utility>

class lru_cache {
  public:
    lru_cache(int capacity) { capacity_ = capacity; }

    int get(int key) {
        auto cache_it = cache_.find(key);
        if (cache_it == cache_.end()) {
            return -1;
        }
        auto lru_it = cache_it->second;
        auto value = lru_it->second;
        lru_.splice(lru_.begin(), lru_, lru_it);
        return value;
    }

    void put(int key, int value) {
        auto cache_it = cache_.find(key);
        if (cache_it != cache_.end()) {
            auto lru_it = cache_it->second;
            lru_it->second = value;
            lru_.splice(lru_.begin(), lru_, lru_it);
            return;
        }
        if (lru_.size() == capacity_) {
            cache_.erase(lru_.back().first);
            lru_.pop_back();
        }
        lru_.emplace_front(key, value);
        cache_[key] = lru_.begin();
    }

  private:
    int capacity_;
    std::unordered_map<int, std::list<std::pair<int, int>>::iterator> cache_;
    std::list<std::pair<int, int>> lru_;
};

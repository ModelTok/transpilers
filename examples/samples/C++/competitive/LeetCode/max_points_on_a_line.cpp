
#include <functional>
#include <numeric>
#include <unordered_map>
#include <utility>
#include <vector>

int max_points(std::vector<std::vector<int>>& points) {

    struct _hash {
        std::size_t operator()(const std::pair<int, int>& _p) const {
            return std::hash<int>{}(_p.first) ^ std::hash<int>{}(_p.second);
        }
    };

    auto maximum = 0;
    for (auto i = 0; i < points.size(); i++) {
        std::unordered_map<std::pair<int, int>, int, _hash> frequency_map;
        auto _overlap = 0;
        auto _horizontal = 0;
        auto _vertical = 0;
        for (auto j = i + 1; j < points.size(); j++) {
            auto delta_x = points[j][0] - points[i][0];
            auto delta_y = points[j][1] - points[i][1];

            if (delta_x == 0 && delta_y == 0) {
                _overlap++;
            } else if (delta_x != 0 && delta_y == 0) {
                _horizontal++;
            } else if (delta_x == 0 && delta_y != 0) {
                _vertical++;
            } else {
                if (delta_x < 0) {
                    delta_x = -delta_x;
                    delta_y = -delta_y;
                }

                auto gcd = std::gcd(delta_x, delta_y);
                delta_x = delta_x / gcd;
                delta_y = delta_y / gcd;

                frequency_map[std::make_pair(delta_x, delta_y)]++;
            }
        }
        for (const auto& [_, frequency] : frequency_map) {
            maximum = std::max(maximum, 1 + _overlap + frequency);
        }
        maximum = std::max(maximum, 1 + _overlap + _horizontal);
        maximum = std::max(maximum, 1 + _overlap + _vertical);
        frequency_map.clear();
    }

    return maximum;
}

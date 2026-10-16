
#include <cstdint>
#include <iostream>
#include <vector>

int main()
{
    std::int64_t total_cells;
    std::int64_t target_cell;
    std::cin >> total_cells >> target_cell;
    std::vector<int> portals(total_cells - 1);
    for (auto i = 0; i < total_cells - 1; i++) {
        std::cin >> portals[i];
    }
    std::int64_t current_cell = 1;
    while (true) {
        if (current_cell == target_cell) {
            std::cout << "YES\n";
            return 0;
        }
        else if (current_cell > target_cell) {
            std::cout << "NO\n";
            return 0;
        }
        current_cell += portals[current_cell - 1];
    }
}

#include "geometric_progression.h"

#include <cmath>
#include <stdexcept>
#include <vector>

namespace mehara::mathematics {

std::vector<double> geometric_progression(double first_term, double common_ratio, int terms) {
    if (terms < 1) {
        throw std::domain_error("terms < 1");
    }

    std::vector<double> progression;
    for (auto term_index = 0; term_index < terms; term_index++) {
        progression.push_back(first_term * std::pow(common_ratio, term_index));
    }

    return progression;
}

}

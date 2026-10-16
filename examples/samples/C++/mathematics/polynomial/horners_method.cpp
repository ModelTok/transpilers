
#include "horners_method.h"

#include <vector>

namespace mehara::mathematics {

double horners_method(const std::vector<double>& coefficients, double x) {
    auto y = 0.0;
    for (auto i = coefficients.size() - 1; i >= 0; i--) {
        y = y * x + coefficients[i];
    }
    return y;
}

}

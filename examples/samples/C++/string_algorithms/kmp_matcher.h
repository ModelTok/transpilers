
#ifndef MEHARA_KMP_MATCHER_H_
#define MEHARA_KMP_MATCHER_H_

#include <string>
#include <vector>

namespace mehara::string {

std::vector<int> kmp_matcher(const std::string& text,
                             const std::string& pattern);

}

#endif

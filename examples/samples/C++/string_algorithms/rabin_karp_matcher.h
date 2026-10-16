
#ifndef MEHARA_RABIN_KARP_H_
#define MEHARA_RABIN_KARP_H_

#include <string>
#include <vector>

namespace mehara::string {

std::vector<int> rabin_karp_matcher(const std::string& text,
                                    const std::string& pattern, int radix,
                                    int prime);

}

#endif

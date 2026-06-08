#include <tuple>
std::tuple<int,int,int,int,int> bitwise_ops(int a, int b) {
    return {a & b, a | b, a ^ b, a << b, a >> b};
}
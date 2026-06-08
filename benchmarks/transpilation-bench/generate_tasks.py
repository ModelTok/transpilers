"""
Transpilation Benchmark Generator
Produces individual JSON task files under benchmarks/tasks/
Run: python generate_tasks.py
"""

import json, os

os.makedirs("benchmarks/tasks", exist_ok=True)

TASKS = []

# ─────────────────────────────────────────────────────────────────────────────
# 1. BITWISE OPERATIONS  (tier 1 – token level)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "001", "name": "bitwise_ops", "tier": 1,
    "concept": "bitwise_arithmetic",
    "tags": ["bitwise", "low-level", "arithmetic"],
    "description": "Perform bitwise AND, OR, XOR, left-shift and right-shift on two integers.",
    "cpp_source": """\
#include <tuple>
std::tuple<int,int,int,int,int> bitwise_ops(int a, int b) {
    return {a & b, a | b, a ^ b, a << b, a >> b};
}""",
    "python_reference": """\
def bitwise_ops(a: int, b: int) -> tuple:
    return (a & b, a | b, a ^ b, a << b, a >> b)""",
    "mojo_reference": """\
fn bitwise_ops(a: Int, b: Int) -> Tuple[Int, Int, Int, Int, Int]:
    return (a & b, a | b, a ^ b, a << b, a >> b)""",
    "tests": [
        {"args": [12, 10], "expected": "(8, 14, 6, 12288, 0)"},
        {"args": [10, 2], "expected": "(2, 10, 8, 40, 2)"},
        {"args": [255, 4], "expected": "(4, 255, 251, 4080, 15)"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 2. FAST EXPONENTIATION  (tier 2 – syntactic + algorithm)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "002", "name": "fast_power", "tier": 2,
    "concept": "recursion_divide_and_conquer",
    "tags": ["recursion", "math", "divide_and_conquer"],
    "description": "Compute base^exp mod m using fast (binary) exponentiation.",
    "cpp_source": """\
long long fast_power(long long base, long long exp, long long mod) {
    long long result = 1;
    base %= mod;
    while (exp > 0) {
        if (exp & 1) result = result * base % mod;
        base = base * base % mod;
        exp >>= 1;
    }
    return result;
}""",
    "python_reference": """\
def fast_power(base: int, exp: int, mod: int) -> int:
    result = 1
    base %= mod
    while exp > 0:
        if exp & 1:
            result = result * base % mod
        base = base * base % mod
        exp >>= 1
    return result""",
    "mojo_reference": """\
fn fast_power(base: Int, exp: Int, mod: Int) -> Int:
    var result: Int = 1
    var b = base % mod
    var e = exp
    while e > 0:
        if e & 1:
            result = result * b % mod
        b = b * b % mod
        e >>= 1
    return result""",
    "tests": [
        {"args": [2, 10, 1000], "expected": "24"},
        {"args": [3, 0, 7], "expected": "1"},
        {"args": [2, 31, 1000000007], "expected": "147483634"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 3. STRING REVERSE  (tier 1)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "003", "name": "string_reverse", "tier": 1,
    "concept": "string_manipulation",
    "tags": ["strings", "indexing"],
    "description": "Return the reverse of a string.",
    "cpp_source": """\
#include <string>
#include <algorithm>
std::string string_reverse(std::string s) {
    std::reverse(s.begin(), s.end());
    return s;
}""",
    "python_reference": """\
def string_reverse(s: str) -> str:
    return s[::-1]""",
    "mojo_reference": """\
fn string_reverse(s: String) -> String:
    var result = String("")
    for i in range(len(s) - 1, -1, -1):
        result += s[i]
    return result""",
    "tests": [
        {"args": ["hello"], "expected": "olleh"},
        {"args": ["abcde"], "expected": "edcba"},
        {"args": ["a"], "expected": "a"},
        {"args": [""], "expected": ""},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 4. PALINDROME CHECK  (tier 1)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "004", "name": "is_palindrome", "tier": 1,
    "concept": "string_two_pointer",
    "tags": ["strings", "two_pointers", "boolean"],
    "description": "Return True if the string is a palindrome (case-insensitive, ignoring spaces).",
    "cpp_source": """\
#include <string>
#include <algorithm>
#include <cctype>
bool is_palindrome(std::string s) {
    s.erase(std::remove(s.begin(), s.end(), ' '), s.end());
    std::transform(s.begin(), s.end(), s.begin(), ::tolower);
    int l = 0, r = s.size() - 1;
    while (l < r) {
        if (s[l++] != s[r--]) return false;
    }
    return true;
}""",
    "python_reference": """\
def is_palindrome(s: str) -> bool:
    s = s.replace(' ', '').lower()
    return s == s[::-1]""",
    "mojo_reference": """\
fn is_palindrome(s: String) -> Bool:
    var cleaned = String("")
    for i in range(len(s)):
        var c = s[i]
        if c != " ":
            cleaned += c.lower()
    var n = len(cleaned)
    var l = 0
    var r = n - 1
    while l < r:
        if cleaned[l] != cleaned[r]:
            return False
        l += 1
        r -= 1
    return True""",
    "tests": [
        {"args": ["racecar"], "expected": "True"},
        {"args": ["A man a plan a canal Panama"], "expected": "True"},
        {"args": ["hello"], "expected": "False"},
        {"args": [""], "expected": "True"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 5. RUN-LENGTH ENCODING  (tier 2)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "005", "name": "run_length_encode", "tier": 2,
    "concept": "string_compression",
    "tags": ["strings", "encoding", "grouping"],
    "description": "Compress a string using run-length encoding. 'aaabbc' → '3a2b1c'.",
    "cpp_source": """\
#include <string>
std::string run_length_encode(const std::string& s) {
    if (s.empty()) return "";
    std::string result;
    int count = 1;
    for (int i = 1; i <= (int)s.size(); i++) {
        if (i < (int)s.size() && s[i] == s[i-1]) {
            count++;
        } else {
            result += std::to_string(count) + s[i-1];
            count = 1;
        }
    }
    return result;
}""",
    "python_reference": """\
def run_length_encode(s: str) -> str:
    if not s:
        return ''
    result, count = [], 1
    for i in range(1, len(s)):
        if s[i] == s[i - 1]:
            count += 1
        else:
            result.append(str(count) + s[i - 1])
            count = 1
    result.append(str(count) + s[-1])
    return ''.join(result)""",
    "mojo_reference": """\
fn run_length_encode(s: String) -> String:
    if len(s) == 0:
        return String("")
    var result = String("")
    var count = 1
    for i in range(1, len(s) + 1):
        if i < len(s) and s[i] == s[i - 1]:
            count += 1
        else:
            result += str(count) + s[i - 1]
            count = 1
    return result""",
    "tests": [
        {"args": ["aaabbc"], "expected": "3a2b1c"},
        {"args": ["abcd"], "expected": "1a1b1c1d"},
        {"args": ["aaaaaa"], "expected": "6a"},
        {"args": [""], "expected": ""},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 6. FIZZBUZZ  (tier 1)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "006", "name": "fizzbuzz", "tier": 1,
    "concept": "conditionals_modulo",
    "tags": ["conditionals", "modulo", "string"],
    "description": "Return FizzBuzz list for 1..n. Multiples of 3→Fizz, 5→Buzz, both→FizzBuzz.",
    "cpp_source": """\
#include <vector>
#include <string>
std::vector<std::string> fizzbuzz(int n) {
    std::vector<std::string> result;
    for (int i = 1; i <= n; i++) {
        if (i % 15 == 0)      result.push_back("FizzBuzz");
        else if (i % 3 == 0)  result.push_back("Fizz");
        else if (i % 5 == 0)  result.push_back("Buzz");
        else                   result.push_back(std::to_string(i));
    }
    return result;
}""",
    "python_reference": """\
def fizzbuzz(n: int) -> list:
    result = []
    for i in range(1, n + 1):
        if i % 15 == 0:   result.append('FizzBuzz')
        elif i % 3 == 0:  result.append('Fizz')
        elif i % 5 == 0:  result.append('Buzz')
        else:             result.append(str(i))
    return result""",
    "mojo_reference": """\
fn fizzbuzz(n: Int) -> List[String]:
    var result = List[String]()
    for i in range(1, n + 1):
        if i % 15 == 0:
            result.append(String("FizzBuzz"))
        elif i % 3 == 0:
            result.append(String("Fizz"))
        elif i % 5 == 0:
            result.append(String("Buzz"))
        else:
            result.append(str(i))
    return result""",
    "tests": [
        {"args": [15], "expected": "['1', '2', 'Fizz', '4', 'Buzz', 'Fizz', '7', '8', 'Fizz', 'Buzz', '11', 'Fizz', '13', '14', 'FizzBuzz']"},
        {"args": [5], "expected": "['1', '2', 'Fizz', '4', 'Buzz']"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 7. COLLATZ SEQUENCE LENGTH  (tier 2)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "007", "name": "collatz_length", "tier": 2,
    "concept": "while_loop_conditional",
    "tags": ["while_loop", "number_theory", "iteration"],
    "description": "Return the number of steps to reach 1 via Collatz: even→n/2, odd→3n+1.",
    "cpp_source": """\
int collatz_length(long long n) {
    int steps = 0;
    while (n != 1) {
        if (n % 2 == 0) n /= 2;
        else            n = 3 * n + 1;
        steps++;
    }
    return steps;
}""",
    "python_reference": """\
def collatz_length(n: int) -> int:
    steps = 0
    while n != 1:
        n = n // 2 if n % 2 == 0 else 3 * n + 1
        steps += 1
    return steps""",
    "mojo_reference": """\
fn collatz_length(n: Int) -> Int:
    var steps = 0
    var x = n
    while x != 1:
        if x % 2 == 0:
            x //= 2
        else:
            x = 3 * x + 1
        steps += 1
    return steps""",
    "tests": [
        {"args": [1], "expected": "0"},
        {"args": [6], "expected": "8"},
        {"args": [27], "expected": "111"},
        {"args": [2], "expected": "1"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 8. FIBONACCI RECURSIVE  (tier 2)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "008", "name": "fibonacci_recursive", "tier": 2,
    "concept": "recursion_base_case",
    "tags": ["recursion", "fibonacci"],
    "description": "Return the nth Fibonacci number using recursion. fib(0)=0, fib(1)=1.",
    "cpp_source": """\
long long fibonacci(int n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}""",
    "python_reference": """\
def fibonacci_recursive(n: int) -> int:
    if n <= 1:
        return n
    return fibonacci_recursive(n - 1) + fibonacci_recursive(n - 2)""",
    "mojo_reference": """\
fn fibonacci_recursive(n: Int) -> Int:
    if n <= 1:
        return n
    return fibonacci_recursive(n - 1) + fibonacci_recursive(n - 2)""",
    "tests": [
        {"args": [0], "expected": "0"},
        {"args": [1], "expected": "1"},
        {"args": [10], "expected": "55"},
        {"args": [15], "expected": "610"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 9. FIBONACCI WITH MEMOIZATION  (tier 3)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "009", "name": "fibonacci_memo", "tier": 3,
    "concept": "memoization_hashmap",
    "tags": ["memoization", "hashmap", "recursion"],
    "description": "Return nth Fibonacci using a memoization dict. Handles n up to 50.",
    "cpp_source": """\
#include <unordered_map>
std::unordered_map<int,long long> memo;
long long fibonacci_memo(int n) {
    if (n <= 1) return n;
    if (memo.count(n)) return memo[n];
    return memo[n] = fibonacci_memo(n-1) + fibonacci_memo(n-2);
}""",
    "python_reference": """\
from functools import lru_cache

@lru_cache(maxsize=None)
def fibonacci_memo(n: int) -> int:
    if n <= 1:
        return n
    return fibonacci_memo(n - 1) + fibonacci_memo(n - 2)""",
    "mojo_reference": """\
fn fibonacci_memo(n: Int, memo: Dict[Int, Int]) -> Int:
    if n <= 1:
        return n
    if n in memo:
        return memo[n]
    var result = fibonacci_memo(n - 1, memo) + fibonacci_memo(n - 2, memo)
    memo[n] = result
    return result""",
    "tests": [
        {"args": [10], "expected": "55"},
        {"args": [30], "expected": "832040"},
        {"args": [50], "expected": "12586269025"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 10. BINARY SEARCH  (tier 2)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "010", "name": "binary_search", "tier": 2,
    "concept": "searching_divide_and_conquer",
    "tags": ["searching", "sorted_array", "divide_and_conquer"],
    "description": "Return the index of target in a sorted list, or -1 if not found.",
    "cpp_source": """\
#include <vector>
int binary_search(const std::vector<int>& arr, int target) {
    int lo = 0, hi = arr.size() - 1;
    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2;
        if      (arr[mid] == target) return mid;
        else if (arr[mid] < target)  lo = mid + 1;
        else                          hi = mid - 1;
    }
    return -1;
}""",
    "python_reference": """\
def binary_search(arr: list, target: int) -> int:
    lo, hi = 0, len(arr) - 1
    while lo <= hi:
        mid = (lo + hi) // 2
        if arr[mid] == target:   return mid
        elif arr[mid] < target:  lo = mid + 1
        else:                    hi = mid - 1
    return -1""",
    "mojo_reference": """\
fn binary_search(arr: List[Int], target: Int) -> Int:
    var lo = 0
    var hi = len(arr) - 1
    while lo <= hi:
        var mid = lo + (hi - lo) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            lo = mid + 1
        else:
            hi = mid - 1
    return -1""",
    "tests": [
        {"args": [[1,3,5,7,9,11], 7], "expected": "3"},
        {"args": [[1,3,5,7,9,11], 1], "expected": "0"},
        {"args": [[1,3,5,7,9,11], 4], "expected": "-1"},
        {"args": [[], 1], "expected": "-1"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 11. TWO SUM  (tier 3 – library/hashmap)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "011", "name": "two_sum", "tier": 3,
    "concept": "hashmap_lookup",
    "tags": ["hashmap", "array", "pairs"],
    "description": "Return indices of the two numbers that add up to target. Assume one solution exists.",
    "cpp_source": """\
#include <vector>
#include <unordered_map>
std::vector<int> two_sum(const std::vector<int>& nums, int target) {
    std::unordered_map<int,int> seen;
    for (int i = 0; i < (int)nums.size(); i++) {
        int complement = target - nums[i];
        if (seen.count(complement))
            return {seen[complement], i};
        seen[nums[i]] = i;
    }
    return {};
}""",
    "python_reference": """\
def two_sum(nums: list, target: int) -> list:
    seen = {}
    for i, x in enumerate(nums):
        if target - x in seen:
            return [seen[target - x], i]
        seen[x] = i
    return []""",
    "mojo_reference": """\
fn two_sum(nums: List[Int], target: Int) -> List[Int]:
    var seen = Dict[Int, Int]()
    for i in range(len(nums)):
        var complement = target - nums[i]
        if complement in seen:
            return List[Int](seen[complement], i)
        seen[nums[i]] = i
    return List[Int]()""",
    "tests": [
        {"args": [[2,7,11,15], 9], "expected": "[0, 1]"},
        {"args": [[3,2,4], 6], "expected": "[1, 2]"},
        {"args": [[3,3], 6], "expected": "[0, 1]"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 12. MAX SUBARRAY (KADANE)  (tier 2)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "012", "name": "max_subarray", "tier": 2,
    "concept": "dynamic_programming_local_global",
    "tags": ["dp", "array", "greedy"],
    "description": "Return the maximum sum of any contiguous subarray (Kadane's algorithm).",
    "cpp_source": """\
#include <vector>
#include <algorithm>
int max_subarray(const std::vector<int>& nums) {
    int max_sum = nums[0], cur = nums[0];
    for (int i = 1; i < (int)nums.size(); i++) {
        cur = std::max(nums[i], cur + nums[i]);
        max_sum = std::max(max_sum, cur);
    }
    return max_sum;
}""",
    "python_reference": """\
def max_subarray(nums: list) -> int:
    max_sum = cur = nums[0]
    for x in nums[1:]:
        cur = max(x, cur + x)
        max_sum = max(max_sum, cur)
    return max_sum""",
    "mojo_reference": """\
fn max_subarray(nums: List[Int]) -> Int:
    var max_sum = nums[0]
    var cur = nums[0]
    for i in range(1, len(nums)):
        cur = max(nums[i], cur + nums[i])
        max_sum = max(max_sum, cur)
    return max_sum""",
    "tests": [
        {"args": [[-2,1,-3,4,-1,2,1,-5,4]], "expected": "6"},
        {"args": [[1]], "expected": "1"},
        {"args": [[-1,-2,-3]], "expected": "-1"},
        {"args": [[5,4,-1,7,8]], "expected": "23"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 13. MERGE SORT  (tier 2)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "013", "name": "merge_sort", "tier": 2,
    "concept": "sorting_divide_and_conquer",
    "tags": ["sorting", "recursion", "divide_and_conquer"],
    "description": "Sort a list of integers using merge sort. Return sorted list.",
    "cpp_source": """\
#include <vector>
std::vector<int> merge_sort(std::vector<int> arr) {
    if (arr.size() <= 1) return arr;
    int mid = arr.size() / 2;
    auto left  = merge_sort(std::vector<int>(arr.begin(), arr.begin() + mid));
    auto right = merge_sort(std::vector<int>(arr.begin() + mid, arr.end()));
    std::vector<int> result;
    int i = 0, j = 0;
    while (i < (int)left.size() && j < (int)right.size())
        result.push_back(left[i] < right[j] ? left[i++] : right[j++]);
    while (i < (int)left.size())  result.push_back(left[i++]);
    while (j < (int)right.size()) result.push_back(right[j++]);
    return result;
}""",
    "python_reference": """\
def merge_sort(arr: list) -> list:
    if len(arr) <= 1:
        return arr
    mid = len(arr) // 2
    left, right = merge_sort(arr[:mid]), merge_sort(arr[mid:])
    result, i, j = [], 0, 0
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:
            result.append(left[i]); i += 1
        else:
            result.append(right[j]); j += 1
    return result + left[i:] + right[j:]""",
    "mojo_reference": """\
fn merge_sort(arr: List[Int]) -> List[Int]:
    if len(arr) <= 1:
        return arr
    var mid = len(arr) // 2
    var left_arr = List[Int]()
    var right_arr = List[Int]()
    for i in range(mid):
        left_arr.append(arr[i])
    for i in range(mid, len(arr)):
        right_arr.append(arr[i])
    var left = merge_sort(left_arr)
    var right = merge_sort(right_arr)
    var result = List[Int]()
    var i = 0
    var j = 0
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:
            result.append(left[i]); i += 1
        else:
            result.append(right[j]); j += 1
    while i < len(left):
        result.append(left[i]); i += 1
    while j < len(right):
        result.append(right[j]); j += 1
    return result""",
    "tests": [
        {"args": [[5,2,8,1,9,3]], "expected": "[1, 2, 3, 5, 8, 9]"},
        {"args": [[1]], "expected": "[1]"},
        {"args": [[-3,0,5,-1]], "expected": "[-3, -1, 0, 5]"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 14. FREQUENCY COUNT  (tier 3 – hashmap)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "014", "name": "frequency_count", "tier": 3,
    "concept": "hashmap_counting",
    "tags": ["hashmap", "counting", "strings"],
    "description": "Return a dict of character frequencies in the string.",
    "cpp_source": """\
#include <string>
#include <map>
std::map<char,int> frequency_count(const std::string& s) {
    std::map<char,int> freq;
    for (char c : s) freq[c]++;
    return freq;
}""",
    "python_reference": """\
def frequency_count(s: str) -> dict:
    freq = {}
    for c in s:
        freq[c] = freq.get(c, 0) + 1
    return freq""",
    "mojo_reference": """\
fn frequency_count(s: String) -> Dict[String, Int]:
    var freq = Dict[String, Int]()
    for i in range(len(s)):
        var c = s[i]
        if c in freq:
            freq[c] += 1
        else:
            freq[c] = 1
    return freq""",
    "tests": [
        {"args": ["hello"], "expected": "{'h': 1, 'e': 1, 'l': 2, 'o': 1}"},
        {"args": ["aaa"], "expected": "{'a': 3}"},
        {"args": [""], "expected": "{}"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 15. SET OPERATIONS  (tier 3)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "015", "name": "set_ops", "tier": 3,
    "concept": "set_operations",
    "tags": ["sets", "intersection", "union", "difference"],
    "description": "Return (union, intersection, difference A-B) of two integer lists treated as sets.",
    "cpp_source": """\
#include <vector>
#include <set>
#include <tuple>
std::tuple<std::vector<int>,std::vector<int>,std::vector<int>>
set_ops(std::vector<int> a, std::vector<int> b) {
    std::set<int> sa(a.begin(), a.end()), sb(b.begin(), b.end());
    std::vector<int> u, inter, diff;
    for (int x : sa) { u.push_back(x); if (sb.count(x)) inter.push_back(x); }
    for (int x : sb) if (!sa.count(x)) u.push_back(x);
    std::sort(u.begin(), u.end());
    for (int x : sa) if (!sb.count(x)) diff.push_back(x);
    return {u, inter, diff};
}""",
    "python_reference": """\
def set_ops(a: list, b: list) -> tuple:
    sa, sb = set(a), set(b)
    return (sorted(sa | sb), sorted(sa & sb), sorted(sa - sb))""",
    "mojo_reference": """\
fn set_ops(a: List[Int], b: List[Int]) -> Tuple[List[Int], List[Int], List[Int]]:
    var sa = Set[Int]()
    var sb = Set[Int]()
    for x in a: sa.add(x[])
    for x in b: sb.add(x[])
    var union_set = sa | sb
    var inter_set = sa & sb
    var diff_set  = sa - sb
    var u = List[Int]()
    var inter = List[Int]()
    var diff = List[Int]()
    for x in union_set: u.append(x[])
    for x in inter_set: inter.append(x[])
    for x in diff_set:  diff.append(x[])
    sort(u); sort(inter); sort(diff)
    return (u, inter, diff)""",
    "tests": [
        {"args": [[1,2,3,4], [3,4,5,6]], "expected": "([1, 2, 3, 4, 5, 6], [3, 4], [1, 2])"},
        {"args": [[1,2], [3,4]], "expected": "([1, 2, 3, 4], [], [1, 2])"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 16. STACK WITH MIN  (tier 3 – OOP + data structure)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "016", "name": "min_stack", "tier": 3,
    "concept": "oop_class_stack",
    "tags": ["oop", "stack", "class", "data_structures"],
    "description": "Stack that supports push, pop, top, and get_min in O(1). Simulate a sequence of operations and return (top, min) after all pushes.",
    "cpp_source": """\
#include <stack>
#include <algorithm>
class MinStack {
    std::stack<int> data, mins;
public:
    void push(int x) {
        data.push(x);
        mins.push(mins.empty() ? x : std::min(x, mins.top()));
    }
    void pop()    { data.pop(); mins.pop(); }
    int  top()    { return data.top(); }
    int  get_min(){ return mins.top(); }
};
std::pair<int,int> min_stack_sim(std::vector<int> values) {
    MinStack s;
    for (int v : values) s.push(v);
    return {s.top(), s.get_min()};
}""",
    "python_reference": """\
class MinStack:
    def __init__(self):
        self.data, self.mins = [], []
    def push(self, x):
        self.data.append(x)
        self.mins.append(x if not self.mins else min(x, self.mins[-1]))
    def pop(self):
        self.data.pop(); self.mins.pop()
    def top(self):     return self.data[-1]
    def get_min(self): return self.mins[-1]

def min_stack(values: list) -> tuple:
    s = MinStack()
    for v in values: s.push(v)
    return (s.top(), s.get_min())""",
    "mojo_reference": """\
struct MinStack:
    var data: List[Int]
    var mins: List[Int]

    fn __init__(inout self):
        self.data = List[Int]()
        self.mins = List[Int]()

    fn push(inout self, x: Int):
        self.data.append(x)
        if len(self.mins) == 0:
            self.mins.append(x)
        else:
            self.mins.append(min(x, self.mins[-1]))

    fn pop(inout self):
        _ = self.data.pop()
        _ = self.mins.pop()

    fn top(self) -> Int:    return self.data[-1]
    fn get_min(self) -> Int: return self.mins[-1]

fn min_stack(values: List[Int]) -> Tuple[Int, Int]:
    var s = MinStack()
    for v in values: s.push(v[])
    return (s.top(), s.get_min())""",
    "tests": [
        {"args": [[3,1,5,2]], "expected": "(2, 1)"},
        {"args": [[5,4,3,2,1]], "expected": "(1, 1)"},
        {"args": [[1,2,3]], "expected": "(3, 1)"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 17. BINARY SEARCH TREE  (tier 3)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "017", "name": "bst_insert_search", "tier": 3,
    "concept": "binary_tree_recursion",
    "tags": ["tree", "recursion", "oop", "pointers"],
    "description": "Insert values into a BST, then return sorted in-order traversal.",
    "cpp_source": """\
#include <vector>
struct Node { int val; Node *left=nullptr, *right=nullptr; Node(int v):val(v){} };
Node* insert(Node* root, int val) {
    if (!root) return new Node(val);
    if (val < root->val) root->left  = insert(root->left,  val);
    else                 root->right = insert(root->right, val);
    return root;
}
void inorder(Node* root, std::vector<int>& out) {
    if (!root) return;
    inorder(root->left, out);
    out.push_back(root->val);
    inorder(root->right, out);
}
std::vector<int> bst_insert_search(std::vector<int> values) {
    Node* root = nullptr;
    for (int v : values) root = insert(root, v);
    std::vector<int> out;
    inorder(root, out);
    return out;
}""",
    "python_reference": """\
class Node:
    def __init__(self, val):
        self.val = val
        self.left = self.right = None

def insert(root, val):
    if root is None: return Node(val)
    if val < root.val: root.left  = insert(root.left,  val)
    else:              root.right = insert(root.right, val)
    return root

def inorder(root):
    if root is None: return []
    return inorder(root.left) + [root.val] + inorder(root.right)

def bst_insert_search(values: list) -> list:
    root = None
    for v in values: root = insert(root, v)
    return inorder(root)""",
    "mojo_reference": """\
struct Node:
    var val: Int
    var left: Int   # index into nodes list (-1 = None)
    var right: Int

    fn __init__(inout self, v: Int):
        self.val = v; self.left = -1; self.right = -1

fn bst_insert_search(values: List[Int]) -> List[Int]:
    var nodes = List[Node]()
    var root = -1
    for v in values:
        var idx = len(nodes)
        nodes.append(Node(v[]))
        if root == -1:
            root = idx; continue
        var cur = root
        while True:
            if v[] < nodes[cur].val:
                if nodes[cur].left == -1: nodes[cur].left = idx; break
                else: cur = nodes[cur].left
            else:
                if nodes[cur].right == -1: nodes[cur].right = idx; break
                else: cur = nodes[cur].right
    var out = List[Int]()
    var stack = List[Int]()
    var cur = root
    while cur != -1 or len(stack) > 0:
        while cur != -1:
            stack.append(cur); cur = nodes[cur].left
        cur = stack.pop()
        out.append(nodes[cur].val)
        cur = nodes[cur].right
    return out""",
    "tests": [
        {"args": [[5,3,7,1,4,6,8]], "expected": "[1, 3, 4, 5, 6, 7, 8]"},
        {"args": [[1,2,3]], "expected": "[1, 2, 3]"},
        {"args": [[5,1,9,2]], "expected": "[1, 2, 5, 9]"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 18. BFS SHORTEST PATH  (tier 3)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "018", "name": "bfs_shortest_path", "tier": 3,
    "concept": "graph_bfs",
    "tags": ["graph", "bfs", "queue", "shortest_path"],
    "description": "Return the shortest path length from src to dst in an undirected graph (adjacency list). Return -1 if unreachable.",
    "cpp_source": """\
#include <vector>
#include <queue>
int bfs_shortest_path(int n, std::vector<std::vector<int>>& adj, int src, int dst) {
    std::vector<int> dist(n, -1);
    std::queue<int> q;
    dist[src] = 0; q.push(src);
    while (!q.empty()) {
        int u = q.front(); q.pop();
        if (u == dst) return dist[u];
        for (int v : adj[u]) if (dist[v] == -1) { dist[v] = dist[u]+1; q.push(v); }
    }
    return -1;
}""",
    "python_reference": """\
from collections import deque

def bfs_shortest_path(n: int, adj: list, src: int, dst: int) -> int:
    dist = [-1] * n
    dist[src] = 0
    q = deque([src])
    while q:
        u = q.popleft()
        if u == dst: return dist[u]
        for v in adj[u]:
            if dist[v] == -1:
                dist[v] = dist[u] + 1
                q.append(v)
    return -1""",
    "mojo_reference": """\
fn bfs_shortest_path(n: Int, adj: List[List[Int]], src: Int, dst: Int) -> Int:
    var dist = List[Int]()
    for _ in range(n): dist.append(-1)
    dist[src] = 0
    var queue = List[Int]()
    queue.append(src)
    var head = 0
    while head < len(queue):
        var u = queue[head]; head += 1
        if u == dst: return dist[u]
        for nb in adj[u]:
            if dist[nb[]] == -1:
                dist[nb[]] = dist[u] + 1
                queue.append(nb[])
    return -1""",
    "tests": [
        {"args": [6, [[1,2],[0,3],[0,4],[1,5],[2,5],[3,4]], 0, 5], "expected": "3"},
        {"args": [4, [[1],[0,2],[1,3],[2]], 0, 3], "expected": "3"},
        {"args": [3, [[1],[0],[]], 0, 2], "expected": "-1"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 19. DFS CYCLE DETECTION  (tier 3)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "019", "name": "has_cycle", "tier": 3,
    "concept": "graph_dfs_cycle",
    "tags": ["graph", "dfs", "cycle_detection"],
    "description": "Return True if a directed graph (adjacency list) contains a cycle.",
    "cpp_source": """\
#include <vector>
bool dfs(int u, std::vector<std::vector<int>>& adj,
         std::vector<int>& color) {
    color[u] = 1;
    for (int v : adj[u]) {
        if (color[v] == 1) return true;
        if (color[v] == 0 && dfs(v, adj, color)) return true;
    }
    color[u] = 2;
    return false;
}
bool has_cycle(int n, std::vector<std::vector<int>> adj) {
    std::vector<int> color(n, 0);
    for (int i = 0; i < n; i++)
        if (color[i] == 0 && dfs(i, adj, color)) return true;
    return false;
}""",
    "python_reference": """\
def has_cycle(n: int, adj: list) -> bool:
    color = [0] * n
    def dfs(u):
        color[u] = 1
        for v in adj[u]:
            if color[v] == 1: return True
            if color[v] == 0 and dfs(v): return True
        color[u] = 2
        return False
    return any(color[i] == 0 and dfs(i) for i in range(n))""",
    "mojo_reference": """\
fn dfs_cycle(u: Int, adj: List[List[Int]], color: List[Int]) -> Bool:
    color[u] = 1
    for nb in adj[u]:
        var v = nb[]
        if color[v] == 1: return True
        if color[v] == 0 and dfs_cycle(v, adj, color): return True
    color[u] = 2
    return False

fn has_cycle(n: Int, adj: List[List[Int]]) -> Bool:
    var color = List[Int]()
    for _ in range(n): color.append(0)
    for i in range(n):
        if color[i] == 0 and dfs_cycle(i, adj, color):
            return True
    return False""",
    "tests": [
        {"args": [4, [[1],[2],[3],[1]]], "expected": "True"},
        {"args": [4, [[1],[2],[3],[]], ], "expected": "False"},
        {"args": [3, [[1,2],[2],[0]]], "expected": "True"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 20. OPERATOR OVERLOADING – VECTOR2D  (tier 3 – OOP)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "020", "name": "vector2d", "tier": 3,
    "concept": "oop_operator_overloading",
    "tags": ["oop", "operator_overloading", "class", "math"],
    "description": "2D vector class supporting +, -, dot product and magnitude. Return (sum.x, sum.y, dot, magnitude_of_a).",
    "cpp_source": """\
#include <cmath>
#include <tuple>
struct Vec2 {
    double x, y;
    Vec2(double x, double y) : x(x), y(y) {}
    Vec2 operator+(const Vec2& o) const { return {x+o.x, y+o.y}; }
    Vec2 operator-(const Vec2& o) const { return {x-o.x, y-o.y}; }
    double dot(const Vec2& o)     const { return x*o.x + y*o.y; }
    double magnitude()            const { return std::sqrt(x*x + y*y); }
};
std::tuple<double,double,double,double>
vector2d(double ax, double ay, double bx, double by) {
    Vec2 a{ax,ay}, b{bx,by};
    auto s = a + b;
    return {s.x, s.y, a.dot(b), a.magnitude()};
}""",
    "python_reference": """\
import math

class Vec2:
    def __init__(self, x, y): self.x, self.y = x, y
    def __add__(self, o): return Vec2(self.x+o.x, self.y+o.y)
    def __sub__(self, o): return Vec2(self.x-o.x, self.y-o.y)
    def dot(self, o):     return self.x*o.x + self.y*o.y
    def magnitude(self):  return math.sqrt(self.x**2 + self.y**2)

def vector2d(ax, ay, bx, by):
    a, b = Vec2(ax, ay), Vec2(bx, by)
    s = a + b
    return (s.x, s.y, a.dot(b), a.magnitude())""",
    "mojo_reference": """\
import math

struct Vec2:
    var x: Float64
    var y: Float64

    fn __init__(inout self, x: Float64, y: Float64):
        self.x = x; self.y = y

    fn __add__(self, o: Vec2) -> Vec2:
        return Vec2(self.x + o.x, self.y + o.y)

    fn dot(self, o: Vec2) -> Float64:
        return self.x * o.x + self.y * o.y

    fn magnitude(self) -> Float64:
        return math.sqrt(self.x ** 2 + self.y ** 2)

fn vector2d(ax: Float64, ay: Float64, bx: Float64, by: Float64
            ) -> Tuple[Float64, Float64, Float64, Float64]:
    var a = Vec2(ax, ay)
    var b = Vec2(bx, by)
    var s = a + b
    return (s.x, s.y, a.dot(b), a.magnitude())""",
    "tests": [
        {"args": [3.0, 4.0, 1.0, 2.0], "expected": "(4.0, 6.0, 11.0, 5.0)"},
        {"args": [0.0, 0.0, 1.0, 1.0], "expected": "(1.0, 1.0, 0.0, 0.0)"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 21. MATRIX MULTIPLICATION  (tier 3 – numerical)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "021", "name": "matrix_multiply", "tier": 3,
    "concept": "numerical_matrix",
    "tags": ["matrix", "numerical", "nested_loops"],
    "description": "Multiply two 2D matrices A (m×k) and B (k×n). Return result matrix.",
    "cpp_source": """\
#include <vector>
std::vector<std::vector<int>> matrix_multiply(
    const std::vector<std::vector<int>>& A,
    const std::vector<std::vector<int>>& B) {
    int m=A.size(), k=A[0].size(), n=B[0].size();
    std::vector<std::vector<int>> C(m, std::vector<int>(n, 0));
    for (int i=0;i<m;i++) for (int j=0;j<n;j++)
        for (int p=0;p<k;p++) C[i][j] += A[i][p]*B[p][j];
    return C;
}""",
    "python_reference": """\
def matrix_multiply(A: list, B: list) -> list:
    m, k, n = len(A), len(A[0]), len(B[0])
    C = [[0]*n for _ in range(m)]
    for i in range(m):
        for j in range(n):
            for p in range(k):
                C[i][j] += A[i][p] * B[p][j]
    return C""",
    "mojo_reference": """\
fn matrix_multiply(A: List[List[Int]], B: List[List[Int]]) -> List[List[Int]]:
    var m = len(A); var k = len(A[0]); var n = len(B[0])
    var C = List[List[Int]]()
    for i in range(m):
        var row = List[Int]()
        for _ in range(n): row.append(0)
        C.append(row)
    for i in range(m):
        for j in range(n):
            for p in range(k):
                C[i][j] += A[i][p] * B[p][j]
    return C""",
    "tests": [
        {"args": [[[1,2],[3,4]], [[5,6],[7,8]]], "expected": "[[19, 22], [43, 50]]"},
        {"args": [[[1,0],[0,1]], [[9,8],[7,6]]], "expected": "[[9, 8], [7, 6]]"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 22. STATISTICS  (tier 3 – numerical)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "022", "name": "statistics_ops", "tier": 3,
    "concept": "numerical_statistics",
    "tags": ["statistics", "numerical", "sorting"],
    "description": "Return (mean, median, population_std_dev) of a list of floats.",
    "cpp_source": """\
#include <vector>
#include <cmath>
#include <algorithm>
#include <tuple>
std::tuple<double,double,double> statistics_ops(std::vector<double> v) {
    int n = v.size();
    double mean = 0; for (double x : v) mean += x; mean /= n;
    std::sort(v.begin(), v.end());
    double median = n%2 ? v[n/2] : (v[n/2-1]+v[n/2])/2.0;
    double var = 0; for (double x : v) var += (x-mean)*(x-mean); var /= n;
    return {mean, median, std::sqrt(var)};
}""",
    "python_reference": """\
import math

def statistics_ops(v: list) -> tuple:
    n = len(v)
    mean = sum(v) / n
    sv = sorted(v)
    median = sv[n//2] if n%2 else (sv[n//2-1]+sv[n//2])/2
    std = math.sqrt(sum((x-mean)**2 for x in v) / n)
    return (mean, median, std)""",
    "mojo_reference": """\
import math

fn statistics_ops(v: List[Float64]) -> Tuple[Float64, Float64, Float64]:
    var n = len(v)
    var mean: Float64 = 0
    for x in v: mean += x[]
    mean /= n
    var sv = sort(v)
    var median: Float64
    if n % 2 == 1:
        median = sv[n // 2]
    else:
        median = (sv[n // 2 - 1] + sv[n // 2]) / 2.0
    var variance: Float64 = 0
    for x in v: variance += (x[] - mean) ** 2
    variance /= n
    return (mean, median, math.sqrt(variance))""",
    "tests": [
        {"args": [[2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]], "expected": "(5.0, 4.5, 2.0)"},
        {"args": [[1.0, 2.0, 3.0]], "expected": "(2.0, 2.0, 0.816496580927726)"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 23. GCD AND LCM  (tier 2 – number theory)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "023", "name": "gcd_lcm", "tier": 2,
    "concept": "number_theory_gcd",
    "tags": ["number_theory", "recursion", "math"],
    "description": "Return (gcd, lcm) of two positive integers using Euclidean algorithm.",
    "cpp_source": """\
#include <tuple>
int gcd(int a, int b) { return b == 0 ? a : gcd(b, a % b); }
std::tuple<int,int> gcd_lcm(int a, int b) {
    int g = gcd(a, b);
    return {g, a / g * b};
}""",
    "python_reference": """\
import math

def gcd_lcm(a: int, b: int) -> tuple:
    g = math.gcd(a, b)
    return (g, a // g * b)""",
    "mojo_reference": """\
fn gcd(a: Int, b: Int) -> Int:
    if b == 0: return a
    return gcd(b, a % b)

fn gcd_lcm(a: Int, b: Int) -> Tuple[Int, Int]:
    var g = gcd(a, b)
    return (g, a // g * b)""",
    "tests": [
        {"args": [12, 18], "expected": "(6, 36)"},
        {"args": [7, 13], "expected": "(1, 91)"},
        {"args": [100, 75], "expected": "(25, 300)"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 24. SIEVE OF ERATOSTHENES  (tier 3)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "024", "name": "sieve_primes", "tier": 3,
    "concept": "sieve_boolean_array",
    "tags": ["number_theory", "sieve", "boolean_array"],
    "description": "Return all primes up to n using the Sieve of Eratosthenes.",
    "cpp_source": """\
#include <vector>
std::vector<int> sieve_primes(int n) {
    std::vector<bool> is_prime(n+1, true);
    is_prime[0] = is_prime[1] = false;
    for (int i = 2; i*i <= n; i++)
        if (is_prime[i])
            for (int j = i*i; j <= n; j += i)
                is_prime[j] = false;
    std::vector<int> primes;
    for (int i = 2; i <= n; i++)
        if (is_prime[i]) primes.push_back(i);
    return primes;
}""",
    "python_reference": """\
def sieve_primes(n: int) -> list:
    is_prime = [True] * (n + 1)
    is_prime[0] = is_prime[1] = False
    for i in range(2, int(n**0.5) + 1):
        if is_prime[i]:
            for j in range(i*i, n+1, i):
                is_prime[j] = False
    return [i for i in range(2, n+1) if is_prime[i]]""",
    "mojo_reference": """\
fn sieve_primes(n: Int) -> List[Int]:
    var is_prime = List[Bool]()
    for _ in range(n + 1): is_prime.append(True)
    is_prime[0] = False
    if n > 0: is_prime[1] = False
    var i = 2
    while i * i <= n:
        if is_prime[i]:
            var j = i * i
            while j <= n:
                is_prime[j] = False
                j += i
        i += 1
    var primes = List[Int]()
    for k in range(2, n + 1):
        if is_prime[k]: primes.append(k)
    return primes""",
    "tests": [
        {"args": [30], "expected": "[2, 3, 5, 7, 11, 13, 17, 19, 23, 29]"},
        {"args": [10], "expected": "[2, 3, 5, 7]"},
        {"args": [2], "expected": "[2]"},
        {"args": [1], "expected": "[]"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 25. COIN CHANGE (DP)  (tier 4 – algorithmic)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "025", "name": "coin_change", "tier": 4,
    "concept": "dynamic_programming_1d",
    "tags": ["dp", "greedy_vs_dp", "optimization"],
    "description": "Return the minimum number of coins to make 'amount'. Return -1 if impossible.",
    "cpp_source": """\
#include <vector>
#include <algorithm>
int coin_change(std::vector<int>& coins, int amount) {
    std::vector<int> dp(amount+1, amount+1);
    dp[0] = 0;
    for (int i = 1; i <= amount; i++)
        for (int c : coins)
            if (c <= i) dp[i] = std::min(dp[i], dp[i-c]+1);
    return dp[amount] > amount ? -1 : dp[amount];
}""",
    "python_reference": """\
def coin_change(coins: list, amount: int) -> int:
    dp = [float('inf')] * (amount + 1)
    dp[0] = 0
    for i in range(1, amount + 1):
        for c in coins:
            if c <= i:
                dp[i] = min(dp[i], dp[i - c] + 1)
    return dp[amount] if dp[amount] != float('inf') else -1""",
    "mojo_reference": """\
fn coin_change(coins: List[Int], amount: Int) -> Int:
    var INF = amount + 1
    var dp = List[Int]()
    for _ in range(amount + 1): dp.append(INF)
    dp[0] = 0
    for i in range(1, amount + 1):
        for c in coins:
            if c[] <= i and dp[i - c[]] + 1 < dp[i]:
                dp[i] = dp[i - c[]] + 1
    return -1 if dp[amount] == INF else dp[amount]""",
    "tests": [
        {"args": [[1,5,11], 15], "expected": "3"},
        {"args": [[2], 3], "expected": "-1"},
        {"args": [[1,2,5], 11], "expected": "3"},
        {"args": [[1], 0], "expected": "0"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 26. EDIT DISTANCE (DP)  (tier 4)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "026", "name": "edit_distance", "tier": 4,
    "concept": "dynamic_programming_2d",
    "tags": ["dp", "strings", "2d_dp"],
    "description": "Return the minimum edit distance (Levenshtein) between two strings.",
    "cpp_source": """\
#include <string>
#include <vector>
#include <algorithm>
int edit_distance(const std::string& a, const std::string& b) {
    int m=a.size(), n=b.size();
    std::vector<std::vector<int>> dp(m+1, std::vector<int>(n+1));
    for (int i=0;i<=m;i++) dp[i][0]=i;
    for (int j=0;j<=n;j++) dp[0][j]=j;
    for (int i=1;i<=m;i++) for (int j=1;j<=n;j++)
        dp[i][j] = a[i-1]==b[j-1] ? dp[i-1][j-1]
            : 1+std::min({dp[i-1][j], dp[i][j-1], dp[i-1][j-1]});
    return dp[m][n];
}""",
    "python_reference": """\
def edit_distance(a: str, b: str) -> int:
    m, n = len(a), len(b)
    dp = [[0]*(n+1) for _ in range(m+1)]
    for i in range(m+1): dp[i][0] = i
    for j in range(n+1): dp[0][j] = j
    for i in range(1, m+1):
        for j in range(1, n+1):
            if a[i-1] == b[j-1]:
                dp[i][j] = dp[i-1][j-1]
            else:
                dp[i][j] = 1 + min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1])
    return dp[m][n]""",
    "mojo_reference": """\
fn edit_distance(a: String, b: String) -> Int:
    var m = len(a); var n = len(b)
    var dp = List[List[Int]]()
    for i in range(m + 1):
        var row = List[Int]()
        for j in range(n + 1):
            if i == 0: row.append(j)
            elif j == 0: row.append(i)
            else: row.append(0)
        dp.append(row)
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if a[i-1] == b[j-1]:
                dp[i][j] = dp[i-1][j-1]
            else:
                dp[i][j] = 1 + min(dp[i-1][j], min(dp[i][j-1], dp[i-1][j-1]))
    return dp[m][n]""",
    "tests": [
        {"args": ["kitten", "sitting"], "expected": "3"},
        {"args": ["", "abc"], "expected": "3"},
        {"args": ["abc", "abc"], "expected": "0"},
        {"args": ["horse", "ros"], "expected": "3"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 27. ACTIVITY SELECTION (GREEDY)  (tier 4)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "027", "name": "activity_selection", "tier": 4,
    "concept": "greedy_interval_scheduling",
    "tags": ["greedy", "sorting", "intervals"],
    "description": "Given start/end times, return the max number of non-overlapping activities.",
    "cpp_source": """\
#include <vector>
#include <algorithm>
int activity_selection(std::vector<int> start, std::vector<int> end) {
    int n = start.size();
    std::vector<int> idx(n);
    std::iota(idx.begin(), idx.end(), 0);
    std::sort(idx.begin(), idx.end(), [&](int a, int b){ return end[a]<end[b]; });
    int count = 0, last_end = -1;
    for (int i : idx) {
        if (start[i] >= last_end) { count++; last_end = end[i]; }
    }
    return count;
}""",
    "python_reference": """\
def activity_selection(start: list, end: list) -> int:
    activities = sorted(zip(end, start))
    count, last_end = 0, -1
    for e, s in activities:
        if s >= last_end:
            count += 1
            last_end = e
    return count""",
    "mojo_reference": """\
fn activity_selection(start: List[Int], end_: List[Int]) -> Int:
    var n = len(start)
    var acts = List[Tuple[Int, Int]]()
    for i in range(n):
        acts.append((end_[i], start[i]))
    sort(acts)
    var count = 0
    var last_end = -1
    for act in acts:
        var s = act[].get[1, Int]()
        var e = act[].get[0, Int]()
        if s >= last_end:
            count += 1
            last_end = e
    return count""",
    "tests": [
        {"args": [[1,3,0,5,8,5],[2,4,6,7,9,9]], "expected": "4"},
        {"args": [[1,2,3],[2,3,4]], "expected": "3"},
        {"args": [[0,2],[1,4]], "expected": "2"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 28. DIJKSTRA  (tier 4)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "028", "name": "dijkstra", "tier": 4,
    "concept": "graph_shortest_path_weighted",
    "tags": ["graph", "priority_queue", "shortest_path", "greedy"],
    "description": "Return shortest distances from src to all nodes. Adjacency list: list of (neighbor, weight).",
    "cpp_source": """\
#include <vector>
#include <queue>
#include <limits>
std::vector<int> dijkstra(int n,
    std::vector<std::vector<std::pair<int,int>>>& adj, int src) {
    std::vector<int> dist(n, INT_MAX);
    dist[src] = 0;
    std::priority_queue<std::pair<int,int>,
        std::vector<std::pair<int,int>>, std::greater<>> pq;
    pq.push({0, src});
    while (!pq.empty()) {
        auto [d, u] = pq.top(); pq.pop();
        if (d > dist[u]) continue;
        for (auto [v, w] : adj[u])
            if (dist[u]+w < dist[v]) { dist[v]=dist[u]+w; pq.push({dist[v],v}); }
    }
    return dist;
}""",
    "python_reference": """\
import heapq

def dijkstra(n: int, adj: list, src: int) -> list:
    dist = [float('inf')] * n
    dist[src] = 0
    pq = [(0, src)]
    while pq:
        d, u = heapq.heappop(pq)
        if d > dist[u]: continue
        for v, w in adj[u]:
            if dist[u] + w < dist[v]:
                dist[v] = dist[u] + w
                heapq.heappush(pq, (dist[v], v))
    return dist""",
    "mojo_reference": """\
fn dijkstra(n: Int, adj: List[List[Tuple[Int,Int]]], src: Int) -> List[Int]:
    var INF = 10**9
    var dist = List[Int]()
    for _ in range(n): dist.append(INF)
    dist[src] = 0
    # min-heap as sorted list (simple for small graphs)
    var pq = List[Tuple[Int,Int]]()
    pq.append((0, src))
    while len(pq) > 0:
        var min_idx = 0
        for i in range(1, len(pq)):
            if pq[i].get[0,Int]() < pq[min_idx].get[0,Int]():
                min_idx = i
        var d = pq[min_idx].get[0,Int]()
        var u = pq[min_idx].get[1,Int]()
        _ = pq.pop(min_idx)
        if d > dist[u]: continue
        for edge in adj[u]:
            var v = edge[].get[0,Int]()
            var w = edge[].get[1,Int]()
            if dist[u] + w < dist[v]:
                dist[v] = dist[u] + w
                pq.append((dist[v], v))
    return dist""",
    "tests": [
        {"args": [5, [[(1,10),(2,3)],[(3,2)],[(1,4),(3,8),(4,2)],[(4,5)],[]], 0], "expected": "[0, 7, 3, 9, 5]"},
        {"args": [3, [[(1,1),(2,4)],[(2,2)],[]], 0], "expected": "[0, 1, 3]"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 29. UNION-FIND  (tier 4)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "029", "name": "union_find", "tier": 4,
    "concept": "disjoint_set_path_compression",
    "tags": ["union_find", "graph", "data_structures", "path_compression"],
    "description": "Given n nodes and list of edges, return the number of connected components.",
    "cpp_source": """\
#include <vector>
struct UF {
    std::vector<int> parent, rank;
    UF(int n) : parent(n), rank(n,0) { std::iota(parent.begin(), parent.end(), 0); }
    int find(int x) { return parent[x]==x ? x : parent[x]=find(parent[x]); }
    bool unite(int a, int b) {
        a=find(a); b=find(b); if(a==b) return false;
        if(rank[a]<rank[b]) std::swap(a,b);
        parent[b]=a; if(rank[a]==rank[b]) rank[a]++;
        return true;
    }
};
int union_find(int n, std::vector<std::vector<int>> edges) {
    UF uf(n);
    for (auto& e : edges) uf.unite(e[0], e[1]);
    int comps = 0;
    for (int i=0;i<n;i++) if(uf.find(i)==i) comps++;
    return comps;
}""",
    "python_reference": """\
def union_find(n: int, edges: list) -> int:
    parent = list(range(n))
    rank = [0] * n

    def find(x):
        if parent[x] != x:
            parent[x] = find(parent[x])
        return parent[x]

    def unite(a, b):
        a, b = find(a), find(b)
        if a == b: return
        if rank[a] < rank[b]: a, b = b, a
        parent[b] = a
        if rank[a] == rank[b]: rank[a] += 1

    for a, b in edges:
        unite(a, b)
    return sum(1 for i in range(n) if find(i) == i)""",
    "mojo_reference": """\
fn union_find(n: Int, edges: List[Tuple[Int,Int]]) -> Int:
    var parent = List[Int]()
    var rank_ = List[Int]()
    for i in range(n):
        parent.append(i); rank_.append(0)

    fn find(x: Int) -> Int:
        var cur = x
        while parent[cur] != cur:
            parent[cur] = parent[parent[cur]]
            cur = parent[cur]
        return cur

    for edge in edges:
        var a = find(edge[].get[0,Int]())
        var b = find(edge[].get[1,Int]())
        if a == b: continue
        if rank_[a] < rank_[b]:
            var tmp = a; a = b; b = tmp
        parent[b] = a
        if rank_[a] == rank_[b]: rank_[a] += 1

    var comps = 0
    for i in range(n):
        if find(i) == i: comps += 1
    return comps""",
    "tests": [
        {"args": [5, [[0,1],[1,2],[3,4]]], "expected": "2"},
        {"args": [5, []], "expected": "5"},
        {"args": [4, [[0,1],[1,2],[2,3]]], "expected": "1"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 30. NEWTON'S METHOD (SQRT)  (tier 3 – numerical)
# ─────────────────────────────────────────────────────────────────────────────
TASKS.append({
    "id": "030", "name": "newton_sqrt", "tier": 3,
    "concept": "numerical_iteration_convergence",
    "tags": ["numerical", "iteration", "floating_point"],
    "description": "Compute sqrt(x) using Newton's method. Return result rounded to 6 decimal places.",
    "cpp_source": """\
#include <cmath>
double newton_sqrt(double x) {
    if (x < 0) return -1;
    double guess = x / 2.0;
    while (std::abs(guess * guess - x) > 1e-10)
        guess = (guess + x / guess) / 2.0;
    return std::round(guess * 1e6) / 1e6;
}""",
    "python_reference": """\
def newton_sqrt(x: float) -> float:
    if x < 0: return -1.0
    guess = x / 2.0
    while abs(guess * guess - x) > 1e-10:
        guess = (guess + x / guess) / 2.0
    return round(guess, 6)""",
    "mojo_reference": """\
import math

fn newton_sqrt(x: Float64) -> Float64:
    if x < 0: return -1.0
    var guess = x / 2.0
    while abs(guess * guess - x) > 1e-10:
        guess = (guess + x / guess) / 2.0
    return math.round(guess * 1e6) / 1e6""",
    "tests": [
        {"args": [4.0], "expected": "2.0"},
        {"args": [2.0], "expected": "1.414214"},
        {"args": [9.0], "expected": "3.0"},
        {"args": [0.0], "expected": "0.0"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# 31-40: ENERGYPLUS REAL-WORLD TASKS
# Source: EnergyPlus open-source building energy simulator (BSD-3-Clause)
# Each function is extracted verbatim from the EnergyPlus C++ codebase and
# adapted to be standalone (no EnergyPlusData* state, no logging sinks).
# ─────────────────────────────────────────────────────────────────────────────

# 31. ORDINAL DAY  (General.cc:706, Linda K. Lawrie, Sept 1997)
TASKS.append({
    "id": "031", "name": "ep_ordinal_day", "tier": 2,
    "concept": "date_arithmetic",
    "tags": ["energyplus", "date", "lookup_table", "real_world"],
    "description": "Return the day-of-year (1–365/366) for a given month, day, and leap-year flag. "
                   "Source: EnergyPlus General.cc OrdinalDay(). Leap=1 adds a day for March onwards.",
    "cpp_source": """\
// Source: EnergyPlus/src/EnergyPlus/General.cc — OrdinalDay()
int ep_ordinal_day(int month, int day, int leap) {
    static constexpr int EndDayofMonth[12] = {31,59,90,120,151,181,212,243,273,304,334,365};
    if (month == 1) return day;
    if (month == 2) return day + EndDayofMonth[0];
    return day + EndDayofMonth[month - 2] + leap;
}""",
    "python_reference": """\
def ep_ordinal_day(month: int, day: int, leap: int) -> int:
    end_day = [31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
    if month == 1:
        return day
    if month == 2:
        return day + end_day[0]
    return day + end_day[month - 2] + leap""",
    "mojo_reference": """\
fn ep_ordinal_day(month: Int, day: Int, leap: Int) -> Int:
    var end_day = List[Int](31,59,90,120,151,181,212,243,273,304,334,365)
    if month == 1:
        return day
    if month == 2:
        return day + end_day[0]
    return day + end_day[month - 2] + leap""",
    "tests": [
        {"args": [1, 15, 0], "expected": "15"},
        {"args": [2, 28, 0], "expected": "59"},
        {"args": [3, 1, 0], "expected": "60"},
        {"args": [3, 1, 1], "expected": "61"},
        {"args": [12, 31, 0], "expected": "365"},
    ]
})

# 32. SAFE DIVIDE  (General.cc:905)
TASKS.append({
    "id": "032", "name": "ep_safe_divide", "tier": 1,
    "concept": "numerical_guard",
    "tags": ["energyplus", "numerical_stability", "division", "real_world"],
    "description": "Divide a by b, guarding against division by zero by clamping |b| to SMALL=1e-10. "
                   "Source: EnergyPlus/General.cc SafeDivide().",
    "cpp_source": """\
// Source: EnergyPlus/src/EnergyPlus/General.cc — SafeDivide()
#include <cmath>
double ep_safe_divide(double a, double b) {
    constexpr double SMALL = 1e-10;
    if (std::abs(b) >= SMALL) return a / b;
    return a / std::copysign(SMALL, b == 0.0 ? 1.0 : b);
}""",
    "python_reference": """\
import math

def ep_safe_divide(a: float, b: float) -> float:
    SMALL = 1e-10
    if abs(b) >= SMALL:
        return a / b
    return a / math.copysign(SMALL, b if b != 0.0 else 1.0)""",
    "mojo_reference": """\
import math

fn ep_safe_divide(a: Float64, b: Float64) -> Float64:
    var SMALL: Float64 = 1e-10
    if abs(b) >= SMALL:
        return a / b
    var sign_b = 1.0 if b >= 0.0 else -1.0
    return a / (SMALL * sign_b)""",
    "tests": [
        {"args": [10.0, 2.0], "expected": "5.0"},
        {"args": [-6.0, 3.0], "expected": "-2.0"},
        {"args": [0.0, 5.0], "expected": "0.0"},
        {"args": [7.5, 0.25], "expected": "30.0"},
    ]
})

# 33. CLAMP  (PlantUtilities.cc:1508, Edwin Lee, Sept 2010)
TASKS.append({
    "id": "033", "name": "ep_clamp", "tier": 1,
    "concept": "numeric_clamp",
    "tags": ["energyplus", "clamp", "range", "real_world"],
    "description": "Clamp value to [lo, hi]. Source: EnergyPlus/PlantUtilities.cc BoundValueToWithinTwoValues().",
    "cpp_source": """\
// Source: EnergyPlus/src/EnergyPlus/PlantUtilities.cc — BoundValueToWithinTwoValues()
#include <algorithm>
double ep_clamp(double value, double lo, double hi) {
    return std::max(lo, std::min(hi, value));
}""",
    "python_reference": """\
def ep_clamp(value: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, value))""",
    "mojo_reference": """\
fn ep_clamp(value: Float64, lo: Float64, hi: Float64) -> Float64:
    return max(lo, min(hi, value))""",
    "tests": [
        {"args": [5.0, 0.0, 10.0], "expected": "5.0"},
        {"args": [-2.0, 0.0, 10.0], "expected": "0.0"},
        {"args": [15.0, 0.0, 10.0], "expected": "10.0"},
        {"args": [3.5, 1.0, 5.0], "expected": "3.5"},
    ]
})

# 34. INTEGER RANGE CHECK  (PlantUtilities.cc:1533, Edwin Lee, Sept 2010)
TASKS.append({
    "id": "034", "name": "ep_int_in_range", "tier": 1,
    "concept": "range_validation",
    "tags": ["energyplus", "validation", "range", "real_world"],
    "description": "Return True if value is in [lo, hi] inclusive. "
                   "Source: EnergyPlus/PlantUtilities.cc IntegerIsWithinTwoValues().",
    "cpp_source": """\
// Source: EnergyPlus/src/EnergyPlus/PlantUtilities.cc — IntegerIsWithinTwoValues()
bool ep_int_in_range(int value, int lo, int hi) {
    return (value >= lo) && (value <= hi);
}""",
    "python_reference": """\
def ep_int_in_range(value: int, lo: int, hi: int) -> bool:
    return lo <= value <= hi""",
    "mojo_reference": """\
fn ep_int_in_range(value: Int, lo: Int, hi: Int) -> Bool:
    return lo <= value <= hi""",
    "tests": [
        {"args": [5, 0, 10], "expected": "True"},
        {"args": [-1, 0, 10], "expected": "False"},
        {"args": [0, 0, 10], "expected": "True"},
        {"args": [11, 0, 10], "expected": "False"},
    ]
})

# 35. AZIMUTH DIFFERENCE  (General.cc:1565)
TASKS.append({
    "id": "035", "name": "ep_azimuth_diff", "tier": 2,
    "concept": "circular_angle_arithmetic",
    "tags": ["energyplus", "geometry", "angles", "real_world"],
    "description": "Return the shortest angular distance (0–180°) between two azimuth angles in degrees. "
                   "Source: EnergyPlus/General.cc rotAzmDiffDeg().",
    "cpp_source": """\
// Source: EnergyPlus/src/EnergyPlus/General.cc — rotAzmDiffDeg()
#include <cmath>
double ep_azimuth_diff(double azm_a, double azm_b) {
    double diff = azm_b - azm_a;
    if (diff > 180.0)       diff = 360.0 - diff;
    else if (diff < -180.0) diff = 360.0 + diff;
    return std::abs(diff);
}""",
    "python_reference": """\
def ep_azimuth_diff(azm_a: float, azm_b: float) -> float:
    diff = azm_b - azm_a
    if diff > 180.0:
        diff = 360.0 - diff
    elif diff < -180.0:
        diff = 360.0 + diff
    return abs(diff)""",
    "mojo_reference": """\
fn ep_azimuth_diff(azm_a: Float64, azm_b: Float64) -> Float64:
    var diff = azm_b - azm_a
    if diff > 180.0:
        diff = 360.0 - diff
    elif diff < -180.0:
        diff = 360.0 + diff
    return abs(diff)""",
    "tests": [
        {"args": [10.0, 20.0], "expected": "10.0"},
        {"args": [10.0, 200.0], "expected": "170.0"},
        {"args": [350.0, 10.0], "expected": "20.0"},
        {"args": [0.0, 270.0], "expected": "90.0"},
    ]
})

# 36. TO UPPER  (UtilityRoutines.cc:609, Linda K. Lawrie, Sept 1997)
TASKS.append({
    "id": "036", "name": "ep_to_upper", "tier": 1,
    "concept": "string_case_conversion",
    "tags": ["energyplus", "strings", "case", "real_world"],
    "description": "Convert a string to uppercase (ASCII letters only). "
                   "Source: EnergyPlus/UtilityRoutines.cc ConvertCaseToUpper() — "
                   "original uses a custom character table; adapted here to std::toupper.",
    "cpp_source": """\
// Source: EnergyPlus/src/EnergyPlus/UtilityRoutines.cc — ConvertCaseToUpper()
// (adapted: original uses explicit char table to be locale-independent)
#include <string>
#include <cctype>
#include <algorithm>
std::string ep_to_upper(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(),
                   [](unsigned char c){ return std::toupper(c); });
    return s;
}""",
    "python_reference": """\
def ep_to_upper(s: str) -> str:
    return s.upper()""",
    "mojo_reference": """\
fn ep_to_upper(s: String) -> String:
    return s.upper()""",
    "tests": [
        {"args": ["hello"], "expected": "HELLO"},
        {"args": ["HeLLo123"], "expected": "HELLO123"},
        {"args": [""], "expected": ""},
        {"args": ["world"], "expected": "WORLD"},
    ]
})

# 37. FIRST NON-SPACE  (UtilityRoutines.cc:673, Linda K. Lawrie, Sept 1997)
TASKS.append({
    "id": "037", "name": "ep_first_nonspace", "tier": 1,
    "concept": "string_scanning",
    "tags": ["energyplus", "strings", "search", "real_world"],
    "description": "Return the index of the first non-space character, or -1 if none. "
                   "Source: EnergyPlus/UtilityRoutines.cc FindNonSpace() — "
                   "original returns std::string::npos; adapted to return -1.",
    "cpp_source": """\
// Source: EnergyPlus/src/EnergyPlus/UtilityRoutines.cc — FindNonSpace()
#include <string>
int ep_first_nonspace(const std::string& s) {
    auto pos = s.find_first_not_of(' ');
    return pos == std::string::npos ? -1 : static_cast<int>(pos);
}""",
    "python_reference": """\
def ep_first_nonspace(s: str) -> int:
    for i, c in enumerate(s):
        if c != ' ':
            return i
    return -1""",
    "mojo_reference": """\
fn ep_first_nonspace(s: String) -> Int:
    for i in range(len(s)):
        if s[i] != ' ':
            return i
    return -1""",
    "tests": [
        {"args": ["  hello"], "expected": "2"},
        {"args": ["world"], "expected": "0"},
        {"args": ["   "], "expected": "-1"},
        {"args": [""], "expected": "-1"},
    ]
})

# 38. MOIST AIR ENTHALPY  (Psychrometrics.hh PsyHFnTdbW, George Shih, May 1976)
TASKS.append({
    "id": "038", "name": "ep_moist_enthalpy", "tier": 2,
    "concept": "psychrometric_formula",
    "tags": ["energyplus", "thermodynamics", "psychrometrics", "real_world"],
    "description": "Compute moist-air enthalpy (J/kg) from dry-bulb temperature (°C) and humidity ratio (kg/kg). "
                   "Source: EnergyPlus/Psychrometrics.hh PsyHFnTdbW(). "
                   "Formula: 1004.84·T + max(W,1e-5)·(2500940 + 1858.95·T). Result rounded to 2 dp.",
    "cpp_source": """\
// Source: EnergyPlus/src/EnergyPlus/Psychrometrics.hh — PsyHFnTdbW()
// ASHRAE HANDBOOK OF FUNDAMENTALS 1972, p100, Eqn 32
#include <algorithm>
double ep_moist_enthalpy(double tdb, double dw) {
    double w = std::max(dw, 1.0e-5);
    return std::round((1.00484e3 * tdb + w * (2.50094e6 + 1.85895e3 * tdb)) * 100.0) / 100.0;
}""",
    "python_reference": """\
def ep_moist_enthalpy(tdb: float, dw: float) -> float:
    w = max(dw, 1e-5)
    return round(1.00484e3 * tdb + w * (2.50094e6 + 1.85895e3 * tdb), 2)""",
    "mojo_reference": """\
import math

fn ep_moist_enthalpy(tdb: Float64, dw: Float64) -> Float64:
    var w = max(dw, 1e-5)
    var h = 1.00484e3 * tdb + w * (2.50094e6 + 1.85895e3 * tdb)
    return math.round(h * 100.0) / 100.0""",
    "tests": [
        {"args": [0.0, 0.0], "expected": "25.01"},
        {"args": [20.0, 0.01], "expected": "45477.99"},
        {"args": [30.0, 0.02], "expected": "81279.37"},
        {"args": [25.0, 0.008], "expected": "45500.31"},
    ]
})

# 39. HEAT OF VAPORIZATION  (Psychrometrics.hh PsyHfgAirFnWTdb, Richard Liesen, May 2001)
TASKS.append({
    "id": "039", "name": "ep_heat_vaporization", "tier": 2,
    "concept": "thermodynamic_formula",
    "tags": ["energyplus", "thermodynamics", "psychrometrics", "real_world"],
    "description": "Compute latent heat of vaporization for moist air (J/kg) at temperature T (°C). "
                   "Source: EnergyPlus/Psychrometrics.hh PsyHfgAirFnWTdb(). "
                   "Formula: (2500940 + 1858.95·T) − 4180·T, where T=max(temp,0).",
    "cpp_source": """\
// Source: EnergyPlus/src/EnergyPlus/Psychrometrics.hh — PsyHfgAirFnWTdb()
#include <algorithm>
double ep_heat_vaporization(double temp) {
    double t = std::max(temp, 0.0);
    return (2500940.0 + 1858.95 * t) - (4180.0 * t);
}""",
    "python_reference": """\
def ep_heat_vaporization(temp: float) -> float:
    t = max(temp, 0.0)
    return (2500940.0 + 1858.95 * t) - (4180.0 * t)""",
    "mojo_reference": """\
fn ep_heat_vaporization(temp: Float64) -> Float64:
    var t = max(temp, 0.0)
    return (2500940.0 + 1858.95 * t) - (4180.0 * t)""",
    "tests": [
        {"args": [0.0], "expected": "2500940.0"},
        {"args": [20.0], "expected": "2454519.0"},
        {"args": [100.0], "expected": "2268835.0"},
        {"args": [-10.0], "expected": "2500940.0"},
    ]
})

# 40. AIR DENSITY  (Psychrometrics.hh PsyRhoAirFnPbTdbW, G.S. Wright, June 1994)
TASKS.append({
    "id": "040", "name": "ep_rho_air", "tier": 2,
    "concept": "ideal_gas_law",
    "tags": ["energyplus", "thermodynamics", "psychrometrics", "physics", "real_world"],
    "description": "Compute moist-air density (kg/m³) from pressure (Pa), dry-bulb temperature (°C), "
                   "and humidity ratio (kg/kg). Uses ideal gas law with Kelvin=273.15. "
                   "Source: EnergyPlus/Psychrometrics.hh PsyRhoAirFnPbTdbW(). Result rounded to 6 dp.",
    "cpp_source": """\
// Source: EnergyPlus/src/EnergyPlus/Psychrometrics.hh — PsyRhoAirFnPbTdbW()
// Wylan & Sontag, Fundamentals of Classical Thermodynamics.
// ASHRAE handbook 1985 Fundamentals, Ch. 6, eqn. (6),(26)
#include <algorithm>
#include <cmath>
constexpr double KELVIN = 273.15;
double ep_rho_air(double pb, double tdb, double dw) {
    double w = std::max(dw, 1.0e-5);
    return std::round(pb / (287.0 * (tdb + KELVIN) * (1.0 + 1.6077687 * w)) * 1e6) / 1e6;
}""",
    "python_reference": """\
def ep_rho_air(pb: float, tdb: float, dw: float) -> float:
    KELVIN = 273.15
    w = max(dw, 1e-5)
    return round(pb / (287.0 * (tdb + KELVIN) * (1.0 + 1.6077687 * w)), 6)""",
    "mojo_reference": """\
import math

fn ep_rho_air(pb: Float64, tdb: Float64, dw: Float64) -> Float64:
    var KELVIN: Float64 = 273.15
    var w = max(dw, 1e-5)
    var rho = pb / (287.0 * (tdb + KELVIN) * (1.0 + 1.6077687 * w))
    return math.round(rho * 1e6) / 1e6""",
    "tests": [
        {"args": [101325.0, 25.0, 0.01], "expected": "1.165395"},
        {"args": [101325.0, 0.0, 0.0], "expected": "1.292488"},
        {"args": [85000.0, 15.0, 0.005], "expected": "1.019627"},
        {"args": [101325.0, 20.0, 0.0], "expected": "1.204309"},
    ]
})

# ─────────────────────────────────────────────────────────────────────────────
# WRITE TO JSON FILES
# ─────────────────────────────────────────────────────────────────────────────
for task in TASKS:
    path = f"benchmarks/tasks/{task['id']}_{task['name']}.json"
    with open(path, "w", encoding="utf-8") as f:
        json.dump(task, f, indent=2, ensure_ascii=False)

print(f"Generated {len(TASKS)} tasks in benchmarks/tasks/")

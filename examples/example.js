// JavaScript — no annotations. The type-inference pass fills the holes.

function addOne(x) {
    return x + 1;
}

function isPositive(x) {
    return x > 0;
}

function sumTo(n) {
    let total = 0;
    for (let i = 0; i < n; i++) {
        total = total + i;
    }
    return total;
}

function fact(n) {
    if (n <= 1) {
        return 1;
    }
    return n * fact(n - 1);
}

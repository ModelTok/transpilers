function add(a: number, b: number): number {
    return a + b;
}

function max2(a: number, b: number): number {
    if (a > b) {
        return a;
    } else {
        return b;
    }
}

function factorial(n: number): number {
    let result: number = 1;
    let i: number = 1;
    while (i <= n) {
        result = result * i;
        i = i + 1;
    }
    return result;
}

function sumTo(n: number): number {
    let total: number = 0;
    for (let i: number = 0; i < n; i++) {
        total = total + i;
    }
    return total;
}

function inRange(x: number, lo: number, hi: number): boolean {
    return x >= lo && x <= hi;
}

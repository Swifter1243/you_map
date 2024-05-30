float easeInOutExpo(float x) {
    return x == 0
    ? 0
    : x == 1
    ? 1
    : x < 0.5 ? pow(2, 20 * x - 10) / 2
    : (2 - pow(2, -20 * x + 10)) / 2;
}
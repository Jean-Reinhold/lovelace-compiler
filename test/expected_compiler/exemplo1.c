#include <stdio.h>

int main() {
    float x;
    float y;
    int resultado;
    x = 10.5;
    y = 5.0;
    if ((x > y)) {
        resultado = 1;
    }
    x = ((x + y) * 2.0);
    y = ((x - y) / 2.0);
    printf("%f\n", x);
    printf("%f\n", y);
    if (((x == y) || (x < 10.0))) {
        resultado = 0;
    }
    printf("%f\n", resultado);
    return 0;
}

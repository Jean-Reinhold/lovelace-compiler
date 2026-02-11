#include <stdio.h>

void imprimir(float x);

void imprimir(float x) {
    printf("%f\n", x);
}

int main() {
    float a;
    a = 42.0;
    imprimir(a);
    return 0;
}

#include <stdio.h>

float f1(float x);
float f2(float x);
float f3(float x);
float f4(float x);
void mostrar(float v);

float f1(float x) {
    return (x + 1.0);
}

float f2(float x) {
    return (x + 2.0);
}

float f3(float x) {
    return (x + 3.0);
}

float f4(float x) {
    return (x + 4.0);
}

void mostrar(float v) {
    printf("%f\n", v);
}

int main() {
    float r;
    r = f1(0.0);
    mostrar(r);
    r = f2(0.0);
    mostrar(r);
    r = f3(0.0);
    mostrar(r);
    r = f4(0.0);
    mostrar(r);
    return 0;
}

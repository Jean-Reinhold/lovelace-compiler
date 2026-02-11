#include <stdio.h>

float dobro(float x);
float quadruplo(float x);
float somaEDobra(float a, float b);

float dobro(float x) {
    return (x * 2.0);
}

float quadruplo(float x) {
    return dobro(dobro(x));
}

float somaEDobra(float a, float b) {
    return dobro((a + b));
}

int main() {
    float r;
    r = quadruplo(3.0);
    printf("%f\n", r);
    r = somaEDobra(2.0, 3.0);
    printf("%f\n", r);
    return 0;
}

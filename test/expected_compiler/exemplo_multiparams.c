#include <stdio.h>

float soma4(float a, float b, float c, float d);

float soma4(float a, float b, float c, float d) {
    return (((a + b) + c) + d);
}

int main() {
    float resultado;
    resultado = soma4(1.0, 2.0, 3.0, 4.0);
    printf("%f\n", resultado);
    return 0;
}

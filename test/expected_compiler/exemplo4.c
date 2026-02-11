#include <stdio.h>

void mostrar(float valor);
float dobro(float x);
float soma3(float a, float b, float c);

void mostrar(float valor) {
    printf("%f\n", valor);
}

float dobro(float x) {
    return (x * 2.0);
}

float soma3(float a, float b, float c) {
    return ((a + b) + c);
}

int main() {
    float i;
    float resultado;
    float x;
    float y;
    float z;
    i = 0.0;
    while ((i < 3.0)) {
        mostrar(i);
        i = (i + 1.0);
    }
    x = 2.0;
    y = 3.0;
    z = 4.0;
    resultado = soma3(x, y, z);
    mostrar(resultado);
    if ((resultado > 5.0)) {
        if ((resultado < 20.0)) {
            resultado = dobro(resultado);
        }
    }
    printf("%f\n", resultado);
    return 0;
}

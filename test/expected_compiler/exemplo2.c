#include <stdio.h>

float calcular(float a, float b);
int verificar(float valor);

float calcular(float a, float b) {
    float resultado;
    resultado = ((a + b) * 2.0);
    return resultado;
}

int verificar(float valor) {
    int ok;
    if ((valor > 0.0)) {
        ok = 1;
    }
    if (((valor < 0.0) || (valor == 0.0))) {
        ok = 0;
    }
    return ok;
}

int main() {
    float num1;
    float num2;
    float resultado;
    int valido;
    float contador;
    num1 = 15.5;
    num2 = 3.2;
    resultado = calcular(num1, num2);
    printf("%f\n", resultado);
    valido = verificar(resultado);
    if ((valido && (resultado > 10.0))) {
        contador = 0.0;
        while ((contador < 5.0)) {
            contador = (contador + 1.0);
            printf("%f\n", contador);
        }
    }
    scanf("%f", &num1);
    scanf("%f", &num2);
    if (((num1 < num2) || (num1 == num2))) {
        printf("%f\n", num1);
    }
    resultado = calcular(num1, num2);
    printf("%f\n", resultado);
    return 0;
}

#include <stdio.h>

//#define HWACC_BASEADDR 0x1A101000
//#define GPIO_REG_PADIN 0x1A101008
//#define GPIO_REG_PADOUT 0x1A101008

//#define GCD_A     0xF0000040
//#define GCD_B     0xF0000044
//#define GCD_EN    0xF0000048
//#define GCD       0xF000004C
//#define GCD_READY 0xF0000050

int gcd(int a, int b) {
    int temp;

    while (b != 0) {
        temp = a % b;
        a = b;
        b = temp;
    }
    return a;
}

int main() {

  const int size = 10;
  int a[10] = {3   , 256, 119, 2048, 99, 16384, 57, 138055, 11111, 1000000};
  int b[10] = {1024, 512, 17 , 2048, 11, 25   , 18, 131072, 99999, 1000000};
  int c[size];

  int i = 0;

  for(i = 0; i < size; i++) {
    //a[i] = i+1;
    //b[i] = i+3;
    c[i] = gcd(a[i], b[i]);
  }

  for(i = 0; i < size; i++) {
    printf("%d, %d, %d\n", a[i], b[i], c[i]);
  }


  // GCD Hardware Accelerator
  //int hwacc_c[size];
  //for(i = 0; i < size; i++) {
  //  *(volatile int*) (GCD_A) = a[i];
  //  *(volatile int*) (GCD_B) = b[i];
  //  *(volatile int*) (GCD_EN) = 0x1;
  //  *(volatile int*) (GCD_EN) = 0x0;
  //  //for(int i = 0; i < 1; i++) {
  //  //  if(*(volatile int*) (GCD_READY) == 1) break;
  //  //}
  //  hwacc_c[i] = *(volatile int*) (GCD);
  //}
  //for(i = 0; i < size; i++) {
  //  printf("hwacc: %d, %d, %d\n", a[i], b[i], hwacc_c[i]);
  //}

  return 0;
}

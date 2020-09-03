#include <SoftwareSerial.h>
#define BT_RXD 8
#define BT_TXD 7

SoftwareSerial bluetooth(BT_RXD, BT_TXD);

void setup(){
  Serial.begin(9600);
  bluetooth.begin(9600);
}

byte id = 0x04;
byte b = 0x00;

byte temp = 0x16;
byte hum = 0x32;

void loop(){
  for (int i=0; i<10; i++) {
    byte message[6];
    while(!bluetooth.available());
    int incomingByte = bluetooth.read();

    // Set ID
    if (i == 1 && incomingByte == 0x49) {
      message[0] = 0x02;
      message[1] = 0x04;
      b = 0x49;
    }

    if (i == 2 && b == 0x49) {
      id = incomingByte;
      message[2] = id;
      message[3] = 0x00;
      message[4] = (message[1] + message[2] + message[3]) % 100;
      message[5] = 0x03;
    }

    // write ID on protocol
    if (i == 1) {
      message[0] = 0x02;
      message[1] = id;
      b = incomingByte;
    }

    // Route by CMD
    if (i == 2) {
      if (b == 0x53 || b == 0x54) {
        if (b == 0x53) {
          temp = incomingByte;
        }
        message[2] = incomingByte;
      }

      if (b == 0x44) {
        message[2] = temp;
        message[3] = hum;
        message[4] = (message[1] + message[2] + message[3]) % 100;
        message[5] = 0x03;
      }

      if (b == 0x51) {
        message[2] = 0x01;
        message[3] = 0x00;
        message[4] = (message[1] + message[2] + message[3]) % 100;
        message[5] = 0x03;
      }
      if (b == 0x4D) {
        message[2] = 0x01;
        message[3] = 0x01;
        message[4] = (message[1] + message[2] + message[3]) % 100;
        message[5] = 0x03;      }
    }

    if (i == 3) {
      if (b == 0x53 || b == 0x54) {
        if (b = 0x53) {
          hum = incomingByte;
        }
        message[3] = incomingByte;
        message[4] = (message[1] + message[2] + message[3]) % 100;
        message[5] = 0x03;
      }
    }

    Serial.print(incomingByte, HEX);
    Serial.print(' ');

    if (incomingByte == 0x03) {
      Serial.print('\n\nSend message: ');

      for (i = 0; i < 6; i++) {
        Serial.print(message[i] + ' ');
      }
      Serial.println();

      bluetooth.write(message, sizeof(message));
      break;
    }
  }
}

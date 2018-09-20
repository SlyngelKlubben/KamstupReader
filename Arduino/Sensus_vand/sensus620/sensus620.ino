/**
 * Based on the BasicHTTPClient.ino
 * from the esp8266-examples
 * Modified 2018-05-02-18
 * Slyngelklubben
 */

#include <Arduino.h>

#include <ESP8266WiFi.h>
#include <ESP8266WiFiMulti.h>

#include <ESP8266HTTPClient.h>

#define USE_SERIAL Serial

ESP8266WiFiMulti WiFiMulti;

String sVal = "";
int LastVal = 0; // remember last value
int ChangeCount = 0;

int j=0;
int i=0;

int MaxValue = 0;     // Max value for setup 
int MinValue = 255;   // Min value for setup

int Upper = 120 ;
int Lower = 100 ;


void setup() {
  // initialize digital pin LED_BUILTIN as an output.
  pinMode(LED_BUILTIN, OUTPUT);
    
    USE_SERIAL.begin(115200);
   // USE_SERIAL.setDebugOutput(true);
  pinMode(A0, INPUT);     // Initialize A0 for input

    USE_SERIAL.println();
    USE_SERIAL.println();
    USE_SERIAL.println();

    for(uint8_t t = 4; t > 0; t--) {
        USE_SERIAL.printf("[SETUP] WAIT %d...\n", t);
        USE_SERIAL.flush();
        delay(1000);
        
    }

    WiFiMulti.addAP("Viggo", "Mallebr0k");
  //  WiFiMulti.addAP("UniFiHome", "thorhauge");

 for(int j=0; j <= 50; j++) {

   for(int i=0; i <= 255; i++) {
      int iVal = analogRead(A0); // read sensor
      if ( iVal > MaxValue) {MaxValue=iVal;}
      if ( iVal < MinValue) {MinValue=iVal;}
   }

   USE_SERIAL.print("Max Value found = ");
   USE_SERIAL.print(MaxValue);
   USE_SERIAL.print(" and Min Value found = ");
   USE_SERIAL.println(MinValue);
 }
  
   Upper = MaxValue-(MaxValue-MinValue)/3; 
   Lower = MinValue+(MaxValue-MinValue)/3;

   USE_SERIAL.print("Upper value = ");
   USE_SERIAL.print(Upper);
   USE_SERIAL.print(" and Lower value = ");
   USE_SERIAL.println(Lower);


}




//int Upper = 120 ;
//int Lower = 100 ;
String State = "low";
int iState = 0; // 0 low



void loop() {
        int iVal = analogRead(A0); // read sensor
          String OutStr1 = String(iVal);
          String OutStr2 = String(ChangeCount);
          String OutStr3 = String(LastVal);
          String oState = String(iState);
          String OutStr4 = "Nu:" + OutStr1 + ". Last: " + OutStr3 + ". ChangeCount: " + OutStr2 + " State: " + oState + "\n" ;
          USE_SERIAL.print(OutStr4);
          if ( iVal > Upper && iState == 0) {
          ChangeCount = ChangeCount + 1;
          iState = 1;
//          OutStr2 = String(ChangeCount);
//          OutStr3 = OutStr1 + ": " + OutStr2 + "\n" ;
//          USE_SERIAL.print(OutStr3);
        }
        if ( iVal < Lower && iState == 1) {
          // ChangeCount = ChangeCount + 1;
          iState = 0;          
        }
        // if( iVal > 100 ) {
        if ( ChangeCount >= 90 ) {
          digitalWrite(LED_BUILTIN, LOW);   // turn the LED on (LOW is the voltage level)
          // wait for WiFi connection
          if((WiFiMulti.run() == WL_CONNECTED)) {
            HTTPClient http;
            http.begin("http://192.168.0.47:3000/hus/public/tyv"); //HTTP

            USE_SERIAL.print("[HTTP] GET...\n");
           // start connection and send HTTP header
           // int httpCode = http.POST("{\"content\":\"YES\"}");
            sVal = String(ChangeCount);
            ChangeCount = 0;
            String myIdent = "\"Sensus620: "  ; // + sVal ;
            String myPre = "{\"content\":" ;
            String myPost = "\"}" ;
            String myJson = myPre + myIdent + sVal + myPost ;
            USE_SERIAL.print(myJson);
            int httpCode = http.POST(myJson);
            // httpCode will be negative on error
            if(httpCode > 0) {
              // HTTP header has been send and Server response header has been handled
              USE_SERIAL.printf("[HTTP] GET... code: %d\n", httpCode);

              // file found at server
              if(httpCode == HTTP_CODE_OK) {
                  String payload = http.getString();
                  USE_SERIAL.println(payload);
              }
            } else {
              USE_SERIAL.printf("[HTTP] GET... failed, error: %s\n", http.errorToString(httpCode).c_str());
            }

            http.end();
            }
          digitalWrite(LED_BUILTIN, HIGH);   // turn the LED off (HIGH is the voltage level)
        }else {
           USE_SERIAL.print(sVal);
        }
    delay(0);
}

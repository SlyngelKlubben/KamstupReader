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

void setup() {

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

//    WiFiMulti.addAP("Viggo", "Mallebr0k");
    WiFiMulti.addAP("UniFiHome", "thorhauge");

}

int Upper = 210 ;
int Lower = 190 ;
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
        if ( 0) {
          // wait for WiFi connection
          if((WiFiMulti.run() == WL_CONNECTED)) {
            HTTPClient http;
            USE_SERIAL.print("[HTTP] begin...\n");
            // configure traged server and url
            http.begin("http://192.168.0.47:3000/hus/public/tyv"); //HTTP

            USE_SERIAL.print("[HTTP] GET...\n");
           // start connection and send HTTP header
           // int httpCode = http.POST("{\"content\":\"YES\"}");
            sVal = String(iVal);
            String myIdent = "\"Sensus620: "  ; // + sVal ;
            String myPre = "{\"content\":" ;
            String myPost = "\"}" ;
            String myJson = myPre + myIdent + sVal + myPost ;
            USE_SERIAL.print(myJson);
            int httpCode = 1 ; // http.POST(myJson);
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
        }else {
           USE_SERIAL.print(sVal);
        }
    delay(0);
}


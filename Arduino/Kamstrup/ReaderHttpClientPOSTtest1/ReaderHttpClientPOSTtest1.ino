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

void loop() {
        int iVal = analogRead(A0); // read sensor
        if( iVal > 100 ) {
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
            String myIdent = "\"Kamstrup: "  ; // + sVal ;
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
        }else {
           USE_SERIAL.print(sVal);
        }
    delay(10);
}


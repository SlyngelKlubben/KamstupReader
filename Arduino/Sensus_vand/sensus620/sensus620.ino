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
int SensorMaxValue=0;
int SensorMinValue=255;
int iState = 1; 
int CycleCount = 1;
int LoopCountInState=0;

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

//    WiFiMulti.addAP("Viggo", "Mallebr0k");
    WiFiMulti.addAP("UniFiHome", "thorhauge");



}

void loop() {
        int iVal = analogRead(A0); // read sensor
        if ( iVal > SensorMaxValue) {SensorMaxValue=iVal;}
        if ( iVal < SensorMinValue) {SensorMinValue=iVal;}
        
        LoopCountInState=LoopCountInState+1;
        int ThresholdUpper = SensorMaxValue-(SensorMaxValue-SensorMinValue)/3; 
        int ThresholdLower = SensorMinValue+(SensorMaxValue-SensorMinValue)/3;      
        
        if ( iVal > ThresholdUpper && iState == 0) {   // If High but in Low state
          CycleCount = CycleCount + 1;
          iState = 1;                         // Now in High state
          LoopCountInState=0;
        }
  
        if ( iVal < ThresholdLower && iState == 1) {   // If Low but in High state
          // CycleCount = CycleCount + 1;   // Not changed - Full cycle only at High state
          iState = 0;                         // Now in Low state 
              USE_SERIAL.println("L");
          LoopCountInState=0;
        } 
        
if (LoopCountInState >= 60000 ) { // 1 loop = 10 ms, 1 hour = 100*60*60 loops , 1 hour = less than 6 ml leak/hour - ready to submit no change to database - if missing = slow leak probability
          // wait for WiFi connection
          digitalWrite(LED_BUILTIN, LOW);   // turn the LED on (LOW is the voltage level)
          if((WiFiMulti.run() == WL_CONNECTED)) {
            HTTPClient http;
            USE_SERIAL.print("[HTTP] begin...\n");
            // configure traged server and url
            http.begin("http://192.168.0.47:3000/hus/public/tyv"); //HTTP

            USE_SERIAL.print("[HTTP] GET...\n");
           // start connection and send HTTP header
           // int httpCode = http.POST("{\"content\":\"YES\"}");
            sVal = String(LoopCountInState) + " Last cycle count: " + String(CycleCount);
            LoopCountInState = 0;
            SensorMinValue=SensorMinValue+1; // To avoid drift over time = increase stability of reading
            SensorMaxValue=SensorMaxValue-1; // To avoid drift over time = increase stability of reading
            String myIdent = "\"WaterLeakTest: "  ; // + sVal ;
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
        }


        
 if (CycleCount >= 9 ) {               // 90 cycles = 1 liter used = ready to submit to database       

          // wait for WiFi connection
          digitalWrite(LED_BUILTIN, LOW);   // turn the LED on (LOW is the voltage level)
          if((WiFiMulti.run() == WL_CONNECTED)) {
            HTTPClient http;
            USE_SERIAL.print("[HTTP] begin...\n");
            // configure traged server and url
            http.begin("http://192.168.0.47:3000/hus/public/tyv"); //HTTP

            USE_SERIAL.print("[HTTP] GET...\n");
           // start connection and send HTTP header
           // int httpCode = http.POST("{\"content\":\"YES\"}");
            sVal = String(CycleCount);
            CycleCount = 0;
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
        }
    delay(10); // A delay of 10 milliseconds or more is needed otherwise the wifi loop will cause refuse wifi connection periodically
}

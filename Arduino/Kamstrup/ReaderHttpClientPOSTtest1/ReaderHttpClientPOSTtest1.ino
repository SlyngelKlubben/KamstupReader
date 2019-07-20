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

#include "parameters.h"

#define USE_SERIAL Serial

ESP8266WiFiMulti WiFiMulti;

String sVal = "";
            String myPre = "" ;
            String myIdent = ""  ; 
            String mySenId = "";
            String myMac = "";
            String myThreshold = "";
            String myThresVal = "" ;
            String myIvalName = "";
            String myIval = "" ;            
            String myPost = "" ;
            String myJson = ""; 

int iVal = 0;
int SensorMaxValue=0;
int SensorMinValue=255;
int ThresholdUpper = SensorMaxValue-(SensorMaxValue-SensorMinValue)/3; 
int ThresholdLower = SensorMinValue+(SensorMaxValue-SensorMinValue)/3;      

int Debug = 0; // 0: no debugging

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

    WiFiMulti.addAP(ssid, password);
        delay(1000);
   
  Serial.println("");
  Serial.println("WIFI IP address: ");
  Serial.println(WiFi.localIP());
}

void loop() {
        iVal = analogRead(A0); // read sensor
        if ( iVal > SensorMaxValue) {SensorMaxValue=iVal; USE_SERIAL.printf("\nSensorMaxValue set to %d. iVal: %d\n", SensorMaxValue, iVal);}
        if ( iVal < SensorMinValue) {SensorMinValue=iVal; USE_SERIAL.printf("\nSensorMinValue set to %d. iVal: %d\n", SensorMinValue, iVal);}

        ThresholdUpper = SensorMaxValue-(SensorMaxValue-SensorMinValue)/3; 
        ThresholdLower = SensorMinValue+(SensorMaxValue-SensorMinValue)/3;      

        if( iVal >  ThresholdLower) { // calibrate 100
            USE_SERIAL.print("HIP\n");
          // wait for WiFi connection
          digitalWrite(LED_BUILTIN, LOW);   // turn the LED on (LOW is the voltage level)
          if((WiFiMulti.run() == WL_CONNECTED)) {
            HTTPClient http;
            USE_SERIAL.print("[HTTP] begin...\n");
            // configure traged server and url
//            http.begin("http://192.168.0.47:3000/hus/public/tyv"); //HTTP
            http.begin(dbstring); //HTTP

            USE_SERIAL.print("[HTTP] GET...\n");
           // start connection and send HTTP header
           // int httpCode = http.POST("{\"content\":\"YES\"}");
            sVal = String(iVal);
            myPre = "{\"content\":" ;
            myIdent = "\"Kamstrup: "  ; // + sVal ;
            mySenId = "\",\"senid\":\"";
            myMac = String(WiFi.macAddress());
            myThreshold = "\",\"threshold\":\"";
            myThresVal = String(ThresholdLower);
            myIvalName = "\",\"intensity\":\"";
            myIval = String(iVal);            
            myPost = "\"}" ;
            myJson = myPre + myIdent + sVal + mySenId + myMac + myThreshold + myThresVal + myIvalName + myIval + myPost ;
            USE_SERIAL.print(myJson);
            USE_SERIAL.print("HEP\n");
            SensorMinValue=SensorMinValue+1; // To avoid drift over time = increase stability of reading
            SensorMaxValue=SensorMaxValue-1; // To avoid drift over time = increase stability of reading
            if(1) {
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
          } else {
            USE_SERIAL.println("No connection to wifi");
          }
          digitalWrite(LED_BUILTIN, HIGH);   // turn the LED off (HIGH is the voltage level)
        }else {
          if(Debug > 0) {USE_SERIAL.printf("%d.",iVal);}
        }
    delay(10);
}

/**
 * Based on the BasicHTTPClient.ino
 * from the esp8266-examples
 * Modified 2018-05-02-18
 * Slyngelklubben
 */

#include <Arduino.h>

#include <ESP8266WiFi.h>
// #include <ESP8266WiFiMulti.h>

#include <ESP8266HTTPClient.h>

#include "parameters.h"

#define USE_SERIAL Serial

// ESP8266WiFiMulti WiFiMulti;

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
int CycleCount = 1;
int iState = 1;

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

  Serial.begin(115200);         // Start the Serial communication to send messages to the computer
  delay(10);
  Serial.println('\n');
  
  WiFi.begin(ssid, password);             // Connect to the network
  Serial.print("Connecting to ");
  Serial.print(ssid); Serial.println(" ...");

  int i = 0;
  while (WiFi.status() != WL_CONNECTED) { // Wait for the Wi-Fi to connect
    delay(1000);
    Serial.print(++i); Serial.print(' ');
  }

  Serial.println('\n');
  Serial.println("Connection established!");  
  Serial.print("IP address:\t");
  Serial.println(WiFi.localIP());         // Send the IP address of the ESP8266 to the computer
  }

void loop() {
        iVal = analogRead(A0); // read sensor
        if ( iVal > SensorMaxValue) {SensorMaxValue=iVal;}
        if ( iVal < SensorMinValue) {SensorMinValue=iVal;}
        
        ThresholdUpper = SensorMaxValue-(SensorMaxValue-SensorMinValue)/3; 
        ThresholdLower = SensorMinValue+(SensorMaxValue-SensorMinValue)/3;      
        
        if ( iVal > ThresholdUpper && iState == 0) {   // If High but in Low state
          CycleCount = CycleCount + 1;
          iState = 1;                         // Now in High state
        }
  
        if ( iVal < ThresholdLower && iState == 1) {   // If Low but in High state
        //   CycleCount = CycleCount + 1;   // Not changed - Full cycle only at High state
          iState = 0;                         // Now in Low state 
        }
        

        if (CycleCount >= 1 ) {               // 90 cycles = 1 liter used = ready to submit to database       

          // wait for WiFi connection
          digitalWrite(LED_BUILTIN, LOW);   // turn the LED on (LOW is the voltage level)
          if((WiFi.status() == WL_CONNECTED)) {
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
            CycleCount = 0;
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

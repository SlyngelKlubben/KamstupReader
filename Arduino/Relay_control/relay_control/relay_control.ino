/*
* Slyngelstue Relay controller
*  Vin - D7
*  GND - D8
*  Signal - D3
*/
 
#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <Arduino.h>
 
#include "parameters.h"  
 
const char* softwareVersion = "20200526"; // Update This!!

// const char* dbask = "lightstate";
// const char* db = "envi";
 
// String variables
char Json[2000];
char s1[300];
char s2[300];
char s3[300];
char dbstring[200];
 
// Envi
//float currentTemp;
//float currentHum;
//float currentPres;
 
String my_status = "" ;
 
// timer variables
unsigned long t1 = 0;
unsigned long t2 = 0;
unsigned long timer_periods = 0;
unsigned long last_timer_value_sent = 0;
unsigned long delta_ms = 0;
 
unsigned long WhenToAsk = 120000;
 
// Last http return code
int LastHttp = 0;
 
// Debugging
bool Debug = true ;
 
// State
bool OnState = false ;  //- Default = Off
 
 
 
// the setup function runs once when you press reset or power the board
void setup() {
 
 
  pinMode(D7, OUTPUT); // D7 = used to power relay (Vin)
  digitalWrite(D7, HIGH);  //  D7 = used to power relay (Vin)
  pinMode(D8, OUTPUT); // D8 = used to power relay (GND)
  digitalWrite(D8, LOW);  //  D8 = used to power relay (GND)
  pinMode(D3, OUTPUT); // D3 = used to signal relay (SIGNAL)
  digitalWrite(D3, OnState);  //  D3 = used to signal relay (SIGNAL) - Default = Off
  
  Serial.begin(115200);
  delay(10);
  // Connecting to WiFi network
  wifi_connect();
  // Construct dbstring
  // dbstring1 hentes fra parameters.h
  sprintf(dbstring, "%s/relay?_page=1&_page_size=1&_select=state&relay_mac=%s", dbstring1, WiFi.macAddress().c_str()); // http://192.168.1.4:3000/hus/public/relay?_page=1&_page_size=1&_select=state&relay_mac=84:F3:EB:3B:7C:ET
 
  Serial.println("Entering loop");
}
 
// the loop function runs over and over again forever
void loop() {
    Serial.println("Start Loop");
    digitalWrite(LED_BUILTIN, LOW);   // turn the LED off (HIGH is the voltage level)
    wifi_signal(s1) ;
    timer(s2);
//    envi_values(s3);
    sprintf(Json, "{%s, %s, \"software_version\":\"%s\"}", s1, s2, softwareVersion); // Generate the json string for the database
    // call_db();
    digitalWrite(LED_BUILTIN, HIGH);   // turn the LED off (HIGH is the voltage level)
 
 
   ask_db();
 
  // After OnState received from database - set state
  digitalWrite(D3, OnState);  //  D3 = used to signal relay (SIGNAL)
 
   delay(WhenToAsk);
 
    // OnState=true;
 
  // digitalWrite(D3, OnState);  //  D3 = used to signal relay (SIGNAL)
  
  // delay(WhenToAsk);
    // OnState=false;
  
}
 
 
void ask_db() {
  /*
   * Call database using globals:
   * dbstring (from parameters.h
   * Json the data payload
   * HTTPClient http object
   * Resets CycleCount = 0, and updates SensorMinValue, SensorMaxValue
   */
 
//curl -H "Content-Type: application/json" -X GET  'http://192.168.1.4:3000/hus/public/envi?id=1'
    OnState=true;
    // WhenToAsk=1000;
 
  if((WiFi.status() == WL_CONNECTED)) {
 
    if(Debug) {
      Serial.printf("[HTTP] dbstring: %s\n", dbstring);
      Serial.printf("[HTTP] data: %s\n", Json);
    }
    HTTPClient http; // here or in loop
    http.begin(dbstring);
    int httpCode = http.GET();    // httpCode will be negative on error
    Serial.printf("[HTTP] httpCode: %d\n", httpCode);
    if(httpCode > 0) {
      if(httpCode == HTTP_CODE_OK) { 
        my_status = http.getString();
      }
      Serial.println("POST request accepted. Server reply: ");
      Serial.println(my_status);
      if(my_status == "[{\"state\":\"off\"}]") {
        OnState=false;
        Serial.println("Switched state to off");
      } else {
        OnState=true;
        Serial.println("Switched state to on");        
      }
    } else {
          Serial.printf("POST failed, error: %s\n", http.errorToString(httpCode).c_str());
      }
      http.end();
   } else {
      Serial.println("No wifi connection") ;
  }
}
 
 
 
void call_db() {
  /*
   * Call database using globals:
   * dbstring (from parameters.h
   * Json the data payload
   * HTTPClient http object
   * Resets CycleCount = 0, and updates SensorMinValue, SensorMaxValue
   */
  if((WiFi.status() == WL_CONNECTED)) {
 
    if(Debug) {
      Serial.printf("[HTTP] dbstring: %s\n", dbstring);
      Serial.printf("[HTTP] data: %s\n", Json);
    }
    HTTPClient http; // here or in loop
    http.begin(dbstring);
    // TODO: Replace this with GET and check if reply is [{"state":"on"}] or [{"state":"off"}]
    int httpCode = http.POST(Json);    // httpCode will be negative on error
    Serial.printf("[HTTP] httpCode: %d\n", httpCode);
    if(httpCode > 0) {
      if(httpCode == HTTP_CODE_OK) {
        my_status = http.getString();
        Serial.println("POST request accepted. Server reply: ");
        Serial.println(my_status);
      }
    } else {
        Serial.printf("POST failed, error: %s\n", http.errorToString(httpCode).c_str());
    }
    http.end();
  } else {
      Serial.println("No wifi connection") ;
  }
}
 
void timer(char* s) {
  /*
   * Return internal counter of milliseconds and delay since  last call
   * Uses global long t1, t2
   */
   t2 = millis();
   if (t1 > t2) {
    timer_periods++ ;
   }
  delta_ms = t2 - t1;
  sprintf(s, "\"time_ms\":%d, \"delta_ms\":%d, \"timer_periods\":%d", t2, delta_ms, timer_periods);
  t1 = millis();
}
 
void wifi_signal(char* s) {
  /*
   * Get IP and signal strength
   * From https://github.com/esp8266/Arduino/issues/132
   * String conversion:  https://forum.arduino.cc/index.php?topic=228884.msg3102705#msg3102705
   */
  sprintf(s, "\"signal\":%d, \"IP\":\"%s\", \"MAC\":\"%s\",\"senid\":\"%s\"", WiFi.RSSI(), WiFi.localIP().toString().c_str(), WiFi.macAddress().c_str(), WiFi.macAddress().c_str());
}
 
void wifi_connect() {
  /*
   *
   * Circuits4you.com
   * Get IP Address of ESP8266 in Arduino IDE
   * Connect to wifi using global parameters loaded from parameters.h:
   *  ssid, password
   */
  Serial.print("Connecting to wifi ssid: ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(100);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());   //You can get IP address assigned to ESP
  Serial.println("Wifi signal (RSSI): ") ;
  Serial.println(WiFi.RSSI()) ;
  Serial.println("");
  WiFi.softAPdisconnect (true);
  Serial.println("Disconnected accesspoint");
  Serial.println("");
}
 

/*
 * Circuits4you.com
 * Get IP Address of ESP8266 in Arduino IDE
*/
#include <ESP8266WiFi.h> 
#include <ESP8266HTTPClient.h> 

#include <Arduino.h>

#include "parameters.h"

const char* softwareVersion = "20191201"; // Update This!!
const char* db = "vand";

// String variables
char Json[2000];
char s1[300];
char s2[300];
char s3[300];
char dbstring[200];

// Sensor Value
int iVal = 0;
int SensorMaxValue=0;
int SensorMinValue=255;
int ThresholdUpper = SensorMaxValue-(SensorMaxValue-SensorMinValue)/3; 
int ThresholdLower = SensorMinValue+(SensorMaxValue-SensorMinValue)/3;      
int CycleCount = 1;
int iState = 1;

// Flow
float Flow_L_per_min = 0;

String my_status = "" ;

// timer variables
unsigned long t1 = 0; // last time flow data sent
unsigned long t2 = 0; // current time
unsigned long t3 = 0; // last time leak data sent
unsigned long timer_periods = 0;
unsigned long last_timer_value_sent = 0;
unsigned long delta_ms = 0;

// Leak time delta: 5 min
const float leak_update_ms = 5*60e3;

// Last http return code
int LastHttp = 0;

// Debugging
bool Debug = true ;


// the setup function runs once when you press reset or power the board
void setup() {
  Serial.begin(115200);
  delay(10);
  // Connecting to WiFi network
  wifi_connect();
  t1 = millis();
  // Construgt dbstring
  sprintf(dbstring, "%s/%s", dbstring1, db);
   // initialize digital pin LED_BUILTIN as an output.
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(A0, INPUT);     // Initialize A0 for input

}

 
// the loop function runs over and over again forever
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

  if (CycleCount >= 9 ) {               // 90 cycles = 1 liter used = ready to submit to database       
    digitalWrite(LED_BUILTIN, LOW);   // turn the LED on (LOW is the voltage level)
    wifi_signal(s1) ;
    timer(s2);
    sensus620_values(s3);
    sprintf(Json, "{%s, %s, %s, \"software_version\":\"%s\"}",s3, s1, s2, softwareVersion); // Generate the json string for the database
    call_db();
    digitalWrite(LED_BUILTIN, HIGH);   // turn the LED off (HIGH is the voltage level)
    t3 = millis();
  }

  t2 = millis() ;
//  if((t2 - t3) > leak_update_ms & (t2 - t1) >= 2*leak_update_ms) { // leak test every 5 minutes     
//   last_leak_cycle_count = CycleCount;
//    t3 = millis();
//  }
  delay(10);
}

void sensus620_values(char* s) {
  /*
   * Return Sensor value from power reader
   * Uses globals iVal (value), ThresholdLower
   */
   // One signal each dL = 0.1L. Flow = 0.1L/delta_ms*60000 ms/min 
   Flow_L_per_min = 6e3 / delta_ms;
  sprintf(s, "\"content\":\"Sensus620: %d\", \"flow_l_per_min\":%.2f, \"intensity\":%d, \"threshold\":%d, \"cycle_count\":%d",CycleCount, Flow_L_per_min,iVal, ThresholdLower, CycleCount);
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
    CycleCount = 0;
    SensorMinValue=SensorMinValue+1; // To avoid drift over time = increase stability of reading
    SensorMaxValue=SensorMaxValue-1; // To avoid drift over time = increase stability of reading

    if(Debug) {
      Serial.printf("[HTTP] dbstring: %s\n", dbstring);
      Serial.printf("[HTTP] data: %s\n", Json);
    }
    HTTPClient http; // here or in loop
    http.begin(dbstring); 
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
        reset_values() ; // Reset all values if database is not available
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
   * Connect to wifi using global parameters loaded from parametes.h:
   *  ssid, password
   */
  Serial.print("Connecting to wifi ssid: ");
  Serial.println(ssid);
   
  WiFi.begin(ssid, password);
 
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
 
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());   //You can get IP address assigned to ESP
  Serial.println("Wifi signal (RSSI): ") ;
  Serial.println(WiFi.RSSI()) ;
  Serial.println("");

}

void reset_values() {
  /*
   * Reset all variables if database is not available
   */
  iVal = 0;
  SensorMaxValue=0;
  SensorMinValue=255;
  ThresholdUpper = SensorMaxValue-(SensorMaxValue-SensorMinValue)/3; 
  ThresholdLower = SensorMinValue+(SensorMaxValue-SensorMinValue)/3;      
  CycleCount = 1;
  iState = 1;
}


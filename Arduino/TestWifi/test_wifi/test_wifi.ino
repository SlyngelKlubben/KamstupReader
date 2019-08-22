/*
 * Circuits4you.com
 * Get IP Address of ESP8266 in Arduino IDE
*/
#include <ESP8266WiFi.h> 
#include <ESP8266HTTPClient.h> 

#include "parameters.h"

// String variables
char Json[500];
char s1[100];
char s2[100];

String my_status = "" ;

// timer variables
unsigned long t1 = 0;
unsigned long t2 = 0;
unsigned long timer_periods = 0;

// Debugging
bool Debug = true ;

// HTTPClient http;

// the setup function runs once when you press reset or power the board
void setup() {
  Serial.begin(115200);
  delay(10);
  // Connecting to WiFi network
  wifi_connect();
  t1 = millis();
}

 
// the loop function runs over and over again forever
void loop() {
  wifi_signal(s1) ;
  timer(s2);
  sprintf(Json, "{%s, %s}", s1, s2); // Generate the json string for the database
//  Serial.println(Json);
  call_db();
  delay(1000);
}

void call_db() {
  /*
   * Call database using globals:
   * dbstring (from parameters.h
   * Json the data payload
   * HTTPClient http object
   */
  if((WiFi.status() == WL_CONNECTED)) {
    if(Debug) {
      Serial.printf("[HTTP] dbstring: %s\n", dbstring);
      Serial.printf("[HTTP] data: %s\n", Json);
    }
    HTTPClient http; // here or in loop
    http.begin(dbstring); 
    int httpCode = http.POST(Json);    // httpCode will be negative on error
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
  sprintf(s, "\"time_ms\":%d, \"delta_ms\":%d, \"timer_periods\":%d", t2, t2-t1, timer_periods);
  t1 = millis();
}

void wifi_signal(char* s) {
  /*
   * Get IP and signal strength
   * From https://github.com/esp8266/Arduino/issues/132
   * String conversion:  https://forum.arduino.cc/index.php?topic=228884.msg3102705#msg3102705
   */
  sprintf(s, "\"signal\":%d, \"IP\":\"%s\", \"MAC\":\"%s\"", WiFi.RSSI(), WiFi.localIP().toString().c_str(), WiFi.macAddress().c_str());
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


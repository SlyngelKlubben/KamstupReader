/*
 * Circuits4you.com
 * Get IP Address of ESP8266 in Arduino IDE
*/
#include <ESP8266WiFi.h> 
#include <ESP8266HTTPClient.h> 
#include <Adafruit_BME280.h>
//Outhmmm #define SEALEVELPRESSURE_HPA (1013.25)

//used for self calibration (maybe)
Adafruit_BME280 bme;

#include <Arduino.h>

#include "parameters.h"

const char* softwareVersion = "20191001"; // Update This!!
const char* db = "envi";

// String variables
char Json[2000];
char s1[300];
char s2[300];
char s3[300];
char dbstring[200];

// Sensor Value
int iVal = 0;
//out int SensorMaxValue=0;
//out int SensorMinValue=255;
//out int ThresholdUpper = SensorMaxValue-(SensorMaxValue-SensorMinValue)/3; 
//out int ThresholdLower = SensorMinValue+(SensorMaxValue-SensorMinValue)/3;      
//out int CycleCount = 1;
//out int iState = 1;

// Envi
bool pirShoot = false;
int pir_State = LOW;
bool pir_pg_state = false;
int pirInputPin = D5;
int pir_val = 0;
float currentTemp;
float currentHum;
float currentPres;
int currentLight;
bool currentPir;

String my_status = "" ;

// timer variables
unsigned long t1 = 0;
unsigned long t2 = 0;
unsigned long timer_periods = 0;
unsigned long last_timer_value_sent = 0;
unsigned long delta_ms = 0;
int timeTrigger = 5*60*1000 ;// loops for triggering send. 5 min
bool timerShoot;

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
  // Construct dbstring
  // dbstring1 hentes fra parameters.h
  sprintf(dbstring, "%s/%s", dbstring1, db);
   // initialize digital pin LED_BUILTIN as an output.
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(A0, INPUT);  // Initialize A0 for input
  pinMode(D6, OUTPUT); //used to power PIR
  pinMode(D7, OUTPUT); //used to power PIR
  
  // Diode setup
  pinMode(BUILTIN_LED, OUTPUT);
  digitalWrite(BUILTIN_LED, HIGH);

  // PIR setup
  pinMode(pirInputPin, INPUT);
  digitalWrite(D6, HIGH);
  digitalWrite(D7, LOW);

  // BME280 setup
  //bme.begin(0x76);
  while (!bme.begin(0x76)) {
  Serial.println("Could not find a valid BME280 sensor, check wiring!");
  delay(1000);
  }

}

 
// the loop function runs over and over again forever
void loop() {
  //out delay(1);

  // PIR read
  pir_val = digitalRead(pirInputPin);  // read input value
  //out analogValue = analogRead(lightSensorPin);
  if (pir_val == HIGH) {            // check if the input is HIGH
    //digitalWrite(BUILTIN_LED, LOW);  // turn LED ON
    if (pir_State == LOW) {
      // we have just turned on
      Serial.println("Motion detected!");
      // We only want to print on the output change, not state
      pir_State = HIGH;
      pir_pg_state = true;
      pirShoot = true;
    }
  } else {
    //digitalWrite(BUILTIN_LED, HIGH); // turn LED OFF
    if (pir_State == HIGH){
      // we have just turned of
      Serial.println("Motion ended!");
      // We only want to print on the output change, not state
      pir_State = LOW;
      pir_pg_state = false;
    }
  }
  t2 = millis();
  if (t2 > t1 + timeTrigger){
    timerShoot = true;
  }


  if (pirShoot or timerShoot){
    digitalWrite(LED_BUILTIN, LOW);   // turn the LED on (LOW is the voltage level)
    wifi_signal(s1) ;
    timer(s2);
    envi_values(s3);
    sprintf(Json, "{%s, %s, %s, \"software_version\":\"%s\"}",s3, s1, s2, softwareVersion); // Generate the json string for the database
    call_db();
    digitalWrite(LED_BUILTIN, HIGH);   // turn the LED off (HIGH is the voltage level)
  }
  delay(10);
}

void envi_values(char* s) {
  currentTemp = bme.readTemperature();
  currentHum =  bme.readHumidity();
  currentPres = bme.readPressure() / 100.0F;
  currentLight = analogRead(A0); // read sensor
  currentPir = pirShoot;
  
  
  /*
   * Return Sensor value from power reader
   * Uses globals iVal (value), ThresholdLower
   */
  sprintf(s, "\"temperature\":%.2f,\"humidity\":%.2f,\"pressure\":%.2f,\"light\":%d,\"pir\":%d", currentTemp, currentHum, currentPres,currentLight,currentPir);
  timerShoot = false;
  pirShoot = false;
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

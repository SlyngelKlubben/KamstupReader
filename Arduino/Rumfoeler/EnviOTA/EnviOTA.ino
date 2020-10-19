/*
 * Slyngelstue BME280 sensor in deep sleep
 *  Vin - D5
 *  GND - D3
 *  SCL - D1
 *  SCA - D2
 *  Remember to short circuit D0 and RST when running (but not when uploading code) 
 */


/*
   Slyngelstue OTA test
*/

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ESP8266httpUpdate.h>
#include <Arduino.h>
#include "parameters.h"  // const char* dbstring1 = "http://192.168.X.X:3000/hus/public";
#include <Adafruit_BME280.h>

Adafruit_BME280 bme; // BME used as shorter name

#define durationSleep  120    // in seconds

const char* softwareVersion = "20201019"; // Update This!!

const char* db = "envi";

// String variables
char Json[2000];
char s1[300];
char s2[300];
char s3[300];
char dbstring[200];

// Envi
float currentTemp;
float currentHum;
float currentPres;

String my_status = "" ;

// timer variables
unsigned long t1 = 0;
unsigned long t2 = 0;
unsigned long timer_periods = 0;
unsigned long last_timer_value_sent = 0;
unsigned long delta_ms = 0;

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

  // Diode setup and Light Sensor setup    
  pinMode(LED_BUILTIN, OUTPUT); // D4 = Led_builtin on Wemos Also used to power Light sensor (ground while LOW = Light on LED)
    digitalWrite(LED_BUILTIN, HIGH);   // turn the LED and BME on (LOW is the voltage level)
  pinMode(D3, OUTPUT); // used to power BME
  pinMode(D5, OUTPUT); // used to power BME
  digitalWrite(D5, LOW); // D5 = +5V (No Power from start)
  digitalWrite(D3, LOW); // D3 = - (ground)
  Serial.println("After BME setup");
//    Serial.println("Entering loop");
}


// the loop function runs over and over again forever
void loop() {
    Serial.println("Start Loop");
    digitalWrite(LED_BUILTIN, LOW);   // turn the LED off (HIGH is the voltage level)
    wifi_signal(s1) ;
    timer(s2);
    envi_values(s3);
    sprintf(Json, "{%s, %s, %s, \"software_version\":\"%s\"}",s3, s1, s2, softwareVersion); // Generate the json string for the database
    call_db();
    digitalWrite(LED_BUILTIN, HIGH);   // turn the LED off (HIGH is the voltage level)
//  }

   checkForUpdates();

  delay(10);
  Serial.println("Entering deep sleep");
  ESP.deepSleep(durationSleep * 1000000);
}

void envi_values(char* s) {
  digitalWrite(D5, HIGH); // D5 = +5V (Power just in time)
  delay(10);
  // BME280 setup
  while (!bme.begin(0x76)) {
  Serial.println("Could not find a valid BME280 sensor, check wiring!");
  delay(1000);
  }
  currentTemp = bme.readTemperature();
  currentHum =  bme.readHumidity();
  currentPres = bme.readPressure() / 100.0F;
   digitalWrite(D5, LOW); // D5 = +5V (Power off when no longer needed)
  /*
   * Return Sensor value from power reader
   * Uses globals iVal (value), ThresholdLower
   */
  sprintf(s, "\"temperature\":%.2f,\"humidity\":%.2f,\"pressure\":%.2f", currentTemp, currentHum, currentPres);
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
    delay(1000);
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










void checkForUpdates() {
  String mac = WiFi.macAddress();
  String fwURL = String( fwUrlBase );
  fwURL.concat( mac );
  String fwVersionURL = fwURL;
  fwVersionURL.concat( ".version" );

  Serial.println( "Checking for firmware updates." );
  Serial.print( "MAC address: " );
  Serial.println( mac );
  Serial.print( "Firmware version URL: " );
  Serial.println( fwVersionURL );

  HTTPClient httpClient;
  httpClient.begin( fwVersionURL );
  int httpCode = httpClient.GET();
  if ( httpCode == 200 ) {
    String newFWVersion = httpClient.getString();
    newFWVersion.trim();
    Serial.print( "Current firmware version: " );
    Serial.println( softwareVersion );
    Serial.print( "Available firmware version: " );
    Serial.println( newFWVersion );

   if ( newFWVersion > softwareVersion ) {
      Serial.println( "Preparing to update" );

      String fwImageURL = fwURL;
      fwImageURL.concat( ".bin" );
     t_httpUpdate_return ret = ESPhttpUpdate.update( fwImageURL );

      switch (ret) {
        case HTTP_UPDATE_FAILED:
          Serial.printf("HTTP_UPDATE_FAILD Error (%d): %s", ESPhttpUpdate.getLastError(), ESPhttpUpdate.getLastErrorString().c_str());
          break;

        case HTTP_UPDATE_NO_UPDATES:
          Serial.println("HTTP_UPDATE_NO_UPDATES");
          break;
      }
    }
    else {
      Serial.println( "Already on latest version" );
    }
  }
  else {
   Serial.print( "Firmware version check failed, got HTTP response code " );
    Serial.println( httpCode );
  }
  httpClient.end();
}

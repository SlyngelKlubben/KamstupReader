
/*
   Slyngelstue OTA test
*/

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ESP8266httpUpdate.h>
#include <Arduino.h>
#include "parameters.h"  // const char* dbstring1 = "http://192.168.X.X:3000/hus/public";


#define durationSleep  120    // in seconds

const char* softwareVersion = "20200425"; // Update This!!

const int FW_VERSION = 1234;

const char* fwUrlBase = "http://192.168.1.4:21451/fota/";



void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);

  wifi_connect();


  checkForUpdates();


  // initialize digital pin LED_BUILTIN as an output.
  pinMode(LED_BUILTIN, OUTPUT);

}





void loop() {
  // put your main code here, to run repeatedly


  digitalWrite(LED_BUILTIN, HIGH);   // turn the LED on (HIGH is the voltage level)
  delay(1000);                       // wait for a second
  digitalWrite(LED_BUILTIN, LOW);    // turn the LED off by making the voltage LOW
  delay(1000);                       // wait for a second



  //  delay(10);
  //  Serial.println("Entering deep sleep");
  //  ESP.deepSleep(durationSleep * 1000000);

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

    Serial.print( "Current firmware version: " );
    Serial.println( FW_VERSION );
    Serial.print( "Available firmware version: " );
    Serial.println( newFWVersion );

    int newVersion = newFWVersion.toInt();

   if ( newVersion > FW_VERSION ) {
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




void wifi_connect() {
  /*

     Circuits4you.com
     Get IP Address of ESP8266 in Arduino IDE
     Connect to wifi using global parameters loaded from parameters.h:
      ssid, password
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
   Serial.println("MAC address: ");
  Serial.println(WiFi.macAddress());   //You can get IP address assigned to ESP
  Serial.println("Wifi signal (RSSI): ") ;
  Serial.println(WiFi.RSSI()) ;
  Serial.println("");
  WiFi.softAPdisconnect (true);
  Serial.println("Disconnected accesspoint");
  Serial.println("");
}

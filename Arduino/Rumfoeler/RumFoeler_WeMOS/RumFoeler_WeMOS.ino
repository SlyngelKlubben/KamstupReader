//http://www.esp8266learning.com/wemos-webserver-example.php
//https://diyprojects.io/unpacking-shield-sht30-temperature-humidity-wemos-d1-mini/#.WtefkZcuBPY

#include <Arduino.h>

#include <ESP8266WiFi.h>

// for http client
#include <ESP8266WiFiMulti.h>
#include <ESP8266HTTPClient.h>
#include <Adafruit_BME280.h>
#define SEALEVELPRESSURE_HPA (1013.25)

Adafruit_BME280 bme;
ESP8266WiFiMulti WiFiMulti;
 
const char* ssid = "Viggo";             //!!!!!!!!!!!!!!!!!!!!! modify this
const char* password = "Mallebr0k";                //!!!!!!!!!!!!!!!!!!!!!modify 
//const char* ssid = "UniFiHome";             //!!!!!!!!!!!!!!!!!!!!! modify this
//const char* password = "thorhauge";                //!!!!!!!!!!!!!!!!!!!!!modify 
//const char* ssid = "TelenorC04AFB";             //!!!!!!!!!!!!!!!!!!!!! modify this
//const char* password = "CEA530B3C2";                //!!!!!!!!!!!!!!!!!!!!!modify 

const char* dbString = "http://192.168.1.200:3000/hus/public/envi" ; // Change this
//const char* dbString = "http://192.168.0.47:3000/hus/public/envi" ; // Change this

// local variables
float deltaTempTrigger = 0.1; // delta C for triggering send
float deltaHumTrigger = 1.0 ; // delta C for triggering send
int delayTrigger = 2*5*60*100 ;// loops for triggering send. 10 ms per loop. 5 min
// initalization
float lastTempSent = 0.0;
float lastHumSent = 0.0 ;
int lastLoopSent = 0    ;
int CycleCount = 0 ;
int analogValue = 0;
// Local vars
String currentTemp = "";
String currentHum = "";
String currentPres = "";
String currentElev = "";
String MAC = "";

float temperature, humidity, pressure, altitude;


WiFiServer server(80);

int lightSensorPin = A0;
int inputPin = D5;
int counter = 0;
int pir_val = 0;
int pir_State = LOW;
bool pir_pg_state = false;

void setup() {
  Serial.begin(115200);
  pinMode(D6, OUTPUT);
  pinMode(D7, OUTPUT);
  delay(10);

  // Diode setup
  pinMode(BUILTIN_LED, OUTPUT);
  digitalWrite(BUILTIN_LED, HIGH);

  // PIR setup
  pinMode(inputPin, INPUT);
  digitalWrite(D6, HIGH);
  digitalWrite(D7, LOW);

  // BME280 setup
  //bme.begin(0x76);
  if (!bme.begin(0x76)) {
  Serial.println("Could not find a valid BME280 sensor, check wiring!");
  while (1);
  }
 
  // Connect to WiFi network
  Serial.println(); 
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
 
  WiFi.begin(ssid, password);
 
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi connected");
 
  // Start the server
  server.begin();
  Serial.println("Server started");
 
  // Print the IP address
  Serial.print("Use this URL : ");
  Serial.print("http://");
  Serial.print(WiFi.localIP());
  Serial.println("/");
  // Pring MAC
  Serial.print("MAC:");
  Serial.println(WiFi.macAddress());
  Serial.println("//");  
  MAC = String(WiFi.macAddress());
  
  WiFiMulti.addAP(ssid, password);

 
}
 
void loop() {
  delay(1);

  // PIR read
  pir_val = digitalRead(inputPin);  // read input value
  analogValue = analogRead(lightSensorPin);
  if (pir_val == HIGH) {            // check if the input is HIGH
    digitalWrite(BUILTIN_LED, LOW);  // turn LED ON
    if (pir_State == LOW) {
      // we have just turned on
      Serial.println("Motion detected!");
      // We only want to print on the output change, not state
      pir_State = HIGH;
      pir_pg_state = true;
      CycleCount = delayTrigger+100;
    }
  } else {
    digitalWrite(BUILTIN_LED, HIGH); // turn LED OFF
    if (pir_State == HIGH){
      // we have just turned of
      Serial.println("Motion ended!");
      // We only want to print on the output change, not state
      pir_State = LOW;
      pir_pg_state = false;
    }
  }


  
  CycleCount = CycleCount + 1;

  // /* Comments
  if (CycleCount >= delayTrigger) {
                        
    delay(2);
    //Serial.println(formatTemp()); 
    // wait for WiFi connection
    // digitalWrite(LED_BUILTIN, LOW);   // turn the LED on (LOW is the voltage level)
    if((WiFiMulti.run() == WL_CONNECTED)) {
      HTTPClient http;
      Serial.print("[HTTP] begin...\n");
      // configure traged server and url
      http.begin(dbString); //HTTP

      Serial.print("[HTTP] GET...\n");
      currentTemp = bme.readTemperature();//getTemp() ; //String(sht30.cTemp);
      currentHum =  bme.readHumidity();//String(sht30.humidity) ;
      currentPres = bme.readPressure() / 100.0F;
      currentElev = bme.readAltitude(SEALEVELPRESSURE_HPA);
      CycleCount = 0;

      String myPreTemp = "{\"temp\":\"" ;
      String myPreHumi = "\",\"humi\":\"";
      String myPrePir = "\",\"pir\":\"";
      String myPreSId = "\",\"senid\":\"";
      String myPrePres = "\",\"press\":\"";
      String myPreLight = "\",\"light\":\"";
      String myPost = "\"}" ;
      //String myJson = myPreTemp + currentTemp + myPreHumi + currentHum + myPrePir + pir_pg_state + myPreSId + WiFi.macAddress() + myPost ;
      String myJson = myPreTemp + currentTemp + myPreHumi + currentHum + myPrePir + pir_pg_state + myPreSId + WiFi.macAddress() + myPrePres + currentPres + myPreLight + analogValue + myPost ;
      Serial.println(myJson);


      
      int httpCode = http.POST(myJson);
      // httpCode will be negative on error
      if(httpCode > 0) {
        // HTTP header has been send and Server response header has been handled
        Serial.printf("[HTTP] GET... code: %d\n", httpCode);

        // file found at server
        if(httpCode == HTTP_CODE_OK) {
            String payload = http.getString();
            Serial.println(payload);
        }
      } else {
        Serial.printf("[HTTP] GET... failed, error: %s\n", http.errorToString(httpCode).c_str());
      }

      Serial.println("Direct: TempC");
      Serial.println(currentTemp);
      Serial.println("Direct: Hum");
      Serial.println(currentHum);
      Serial.println("Direct: Pressure");
      Serial.println(currentPres);
      Serial.println("Elevation");
      Serial.println(currentElev);
      Serial.println("Direct: Light");
      Serial.println(analogValue);
      Serial.println("///");

      http.end();
      }
    //digitalWrite(LED_BUILTIN, HIGH);   // turn the LED off (HIGH is the voltage level)
  }

// Comments */ 
  
  // Check if a client has connected
  WiFiClient client = server.available();
  if (!client) {
    return;
  }
 
  // Wait until the client sends some data
  Serial.println("new client");
  if(!client.available()){
    delay(1);
  }
 
  // Read the first line of the request
  String request = client.readStringUntil('\r');
  Serial.println(request);
  client.flush();
 
  // Match the request
 
  int value = LOW;
  if (request.indexOf("/LED=ON") != -1){
    digitalWrite(BUILTIN_LED, HIGH);
    value = HIGH;
  } 
  if (request.indexOf("/LED=OFF") != -1){
    digitalWrite(BUILTIN_LED, LOW);
    value = LOW;
  }
 
  if (request.indexOf("/GetEnviroment") != -1){
    Serial.println("Direct: TempC");
    Serial.println(currentTemp);
    Serial.println("Direct: Hum");
    Serial.println(currentHum);
    Serial.println("Direct: Pressure");
    Serial.println(currentPres);
    Serial.println("Direct: Light");
    Serial.println(analogValue);
    Serial.println();
    
  }
 
  // Return the response
  client.println("HTTP/1.1 200 OK");
  client.println("Content-Type: text/html");
  client.println(""); //  do not forget this one
  client.println("<!DOCTYPE HTML>");
  client.println("<html>");

  client.print("MAC: ");
  client.println(WiFi.macAddress());
  client.print("<br>");
   
  client.print("Led pin is now: ");
 
  if(value == HIGH) {
    client.print("On");  
  } else {
    client.print("Off");
  }

  client.print("<br>Temp is: ");
  client.print(currentTemp);
  client.print("<br>Humidity is: ");
  client.print(currentHum);
    
  client.println("<br><br>");
  client.println("Click <a href=\"/LED=ON\">here</a> turn the LED on pin 5 ON<br>");
  client.println("Click <a href=\"/LED=OFF\">here</a> turn the LED on pin 5 OFF<br>");
  client.println("Click <a href=\"/GetEnviroment\">here</a> for enviroment<br>");
  client.println("</html>");

  counter = counter + 1;
  Serial.println(counter);
  if (counter > 120) {
     // getEnv();
     counter = 0;
  }
 
  delay(1);
  Serial.println("Client disconnected");
  Serial.println("");
 
}

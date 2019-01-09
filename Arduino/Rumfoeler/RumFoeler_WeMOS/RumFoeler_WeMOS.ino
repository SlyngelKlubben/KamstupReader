//http://www.esp8266learning.com/wemos-webserver-example.php
//https://diyprojects.io/unpacking-shield-sht30-temperature-humidity-wemos-d1-mini/#.WtefkZcuBPY

#include <Arduino.h>

#include <ESP8266WiFi.h>

// for http client
#include <ESP8266WiFiMulti.h>
#include <ESP8266HTTPClient.h>
ESP8266WiFiMulti WiFiMulti;


#include <WEMOS_SHT3X.h>
SHT3X sht30(0x45);
 
//const char* ssid = "Viggo";             //!!!!!!!!!!!!!!!!!!!!! modify this
//const char* password = "Mallebr0k";                //!!!!!!!!!!!!!!!!!!!!!modify 
const char* ssid = "UniFiHome";             //!!!!!!!!!!!!!!!!!!!!! modify this
const char* password = "thorhauge";                //!!!!!!!!!!!!!!!!!!!!!modify 
const char* dbString = "http://192.168.0.47:3000/hus/public/tyv" ; // Change this

// local variables
float deltaTempTrigger = 0.1; // delta C for triggering send
float deltaHumTrigger = 1.0 ; // delta C for triggering send
int delayTrigger = 5*60*100 ;// loops for triggering send. 10 ms per loop. 5 min
// initalization
float lastTempSent = 0.0;
float lastHumSent = 0.0 ;
int lastLoopSent = 0    ;
int CycleCount = 0 ;
// Local vars
String currentTemp = "";
String currentHum = "";
String MAC = "";
 
#define sigPin D3 
int ledPin = D4;          //connect led pin to d4 and ground
WiFiServer server(80);

int counter = 0;

void setup() {
  Serial.begin(115200);
  delay(10);
 
 
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW);
 
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
CycleCount = CycleCount + 1;

// /* Comments
if (CycleCount >= delayTrigger) {                    

   Serial.println(formatTemp()); 

          // wait for WiFi connection
          digitalWrite(LED_BUILTIN, LOW);   // turn the LED on (LOW is the voltage level)
          if((WiFiMulti.run() == WL_CONNECTED)) {
            HTTPClient http;
            Serial.print("[HTTP] begin...\n");
            // configure traged server and url
            http.begin(dbString); //HTTP

            Serial.print("[HTTP] GET...\n");
           // start connection and send HTTP header
           // int httpCode = http.POST("{\"content\":\"YES\"}");
            sht30.get();
            currentTemp = getTemp() ; //String(sht30.cTemp);
            currentHum =  String(sht30.humidity) ;
            CycleCount = 0;
            String myIdent = "\"SSHT3_TempC_celler: "  ; // + currentTemp ;
            String myPre = "{\"content\":" ;
            String myPost = "\"}" ;
            String myJson = myPre + myIdent + currentTemp + myPost ;
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
            Serial.println(sht30.cTemp);
            Serial.println("Direct: TempF");
            Serial.println(sht30.fTemp);
            Serial.println("Direct: Hum");
            Serial.println(sht30.humidity);
            Serial.println("///");

            http.end();
            }
          digitalWrite(LED_BUILTIN, HIGH);   // turn the LED off (HIGH is the voltage level)
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
    digitalWrite(ledPin, HIGH);
    value = HIGH;
  } 
  if (request.indexOf("/LED=OFF") != -1){
    digitalWrite(ledPin, LOW);
    value = LOW;
  }
 
  if (request.indexOf("/GetEnviroment") != -1){
    sht30.get();
    Serial.print("Temperature in Celsius : ");
    Serial.println(sht30.cTemp);
    Serial.print("Temperature in Fahrenheit : ");
    Serial.println(sht30.fTemp);
    Serial.print("Relative Humidity : ");
    Serial.println(sht30.humidity);
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
  client.print(sht30.cTemp-10);
  client.print("<br>Humidity is: ");
  client.print(sht30.humidity);
    
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

void getEnv(){
  sht30.get();
  Serial.print("Temperature in Celsius : ");
  Serial.println(sht30.cTemp);
  Serial.print("Temperature in Fahrenheit : ");
  Serial.println(sht30.fTemp);
  Serial.print("Relative Humidity : ");
  Serial.println(sht30.humidity);
  Serial.println();
}

String getTemp(){
  sht30.get();
  Serial.print("getTemp Temperature in Celsius : ");
  Serial.println(sht30.cTemp);
  Serial.print("getTemp as string : ");
  Serial.println(String(sht30.cTemp));
  return String(sht30.cTemp);
}

String formatTemp() {
  // {"content":"SSHT3_TempC_celler: 32.14"}
//  String myTemp = getTemp();
  sht30.get();
  char buffer[50];
  sprintf(buffer, "{\"content\":\"TempC_celler: %.2f\"}", sht30.cTemp);
  Serial.println(buffer);
  return buffer;
}


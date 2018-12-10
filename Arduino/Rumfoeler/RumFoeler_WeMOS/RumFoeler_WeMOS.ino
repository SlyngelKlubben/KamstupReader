//http://www.esp8266learning.com/wemos-webserver-example.php
//https://diyprojects.io/unpacking-shield-sht30-temperature-humidity-wemos-d1-mini/#.WtefkZcuBPY

#include <ESP8266WiFi.h>
#include <WEMOS_SHT3X.h>
SHT3X sht30(0x45);
 
//const char* ssid = "Viggo";             //!!!!!!!!!!!!!!!!!!!!! modify this
//const char* password = "Mallebr0k";                //!!!!!!!!!!!!!!!!!!!!!modify 
const char* ssid = "UniFiHome";             //!!!!!!!!!!!!!!!!!!!!! modify this
const char* password = "thorhauge";                //!!!!!!!!!!!!!!!!!!!!!modify 

 
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
 
}
 
void loop() {
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
     getEnv();
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


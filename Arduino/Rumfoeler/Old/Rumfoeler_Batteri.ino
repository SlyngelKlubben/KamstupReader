#include <Arduino.h>
#include <ESP8266WiFi.h>

// for http client
#include <ESP8266WiFiMulti.h>
#include <ESP8266HTTPClient.h>
ESP8266WiFiMulti WiFiMulti;


#include <WEMOS_SHT3X.h>
SHT3X sht30(0x45);
 
const char* ssid = "Viggo";             //!!!!!!!!!!!!!!!!!!!!! modify this
const char* password = "Mallebr0k";                //!!!!!!!!!!!!!!!!!!!!!modify 
//const char* ssid = "UniFiHome";             //!!!!!!!!!!!!!!!!!!!!! modify this
//const char* password = "thorhauge";                //!!!!!!!!!!!!!!!!!!!!!modify 
const char* dbString = "http://192.168.0.200:3000/hus/public/envi" ; // Change this

// local variables
float deltaTempTrigger = 0.1; // delta C for triggering send
float deltaHumTrigger = 1.0 ; // delta C for triggering send
int delayTrigger = 2*5*60*100 ;// loops for triggering send. 10 ms per loop. 5 min
// initalization
float lastTempSent = 0.0;
float lastHumSent = 0.0 ;
int lastLoopSent = 0    ;
int CycleCount = 0 ;
// Local vars
String currentTemp = "";
String currentHum = "";
String MAC = "";

WiFiServer server(80);

int inputPin = D5;
int counter = 0;
int pir_val = 0;
int pir_State = LOW;
bool pir_pg_state = false;

void setup() {
  
  Serial.begin(115200);
  Serial.setTimeout(2000);
  
  // Wait for serial to initialize.
  while (!Serial) { }

  Serial.println("Device Started");
  Serial.println("-------------------------------------");
  Serial.println("Running Deep Sleep Firmware!");
  Serial.println("-------------------------------------");

  connect();
  
  if((WiFiMulti.run() == WL_CONNECTED)) {
    
    HTTPClient http;
    Serial.print("[HTTP] begin...\n");
    // configure traged server and url
    http.begin(dbString); //HTTP
    
    Serial.print("[HTTP] GET...\n");
      
    sht30.get();
    currentTemp = String(sht30.cTemp);
    currentHum =  String(sht30.humidity) ;
    pir_val = digitalRead(inputPin);
    
    String myPreTemp = "{\"temp\":\"" ;
    String myPreHumi = "\",\"humi\":\"";
    String myPrePir = "\",\"pir\":\"";
    String myPreSId = "\",\"senid\":\"";
    String myPost = "\"}" ;
    String myJson = myPreTemp + currentTemp + myPreHumi + currentHum + myPrePir + pir_val + myPreSId + WiFi.macAddress() + myPost ;
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
    Serial.println("Direct: Hum");
    Serial.println(sht30.humidity);
    Serial.println("Pir State");
    Serial.println(pir_val);
    Serial.println("///");

    Serial.println("Going into deep sleep for 60 seconds");
    ESP.deepSleep(60e6); // 20e6 is 20 microseconds
  }
}

void connect(){

  // Diode setup
  pinMode(BUILTIN_LED, OUTPUT);
  digitalWrite(BUILTIN_LED, HIGH);

  // PIR setup
  pinMode(inputPin, INPUT);
 
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
  }

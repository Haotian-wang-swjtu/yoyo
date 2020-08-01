#include "sea_esp32_qspi.h"
#include "SimpleDHT.h"
#include "string.h"

#include "AWS_IOT.h"
#include "WiFi.h"

AWS_IOT hornbill;

char WIFI_SSID[]="wei_wifi01";
char WIFI_PASSWORD[]="weifei1983";
char HOST_ADDRESS[]="a3w1of7pmgj85v-ats.iot.us-east-1.amazonaws.com";
char CLIENT_ID[]= "ESP32client";
char TOPIC_NAME[]= "Gyro_wht";

const char aws_root_ca_pem[]={"-----BEGIN CERTIFICATE-----\n\
MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF\
ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6\
b24gUm9vdCBDQSAxMB4XDTE1MDUyNjAwMDAwMFoXDTM4MDExNzAwMDAwMFowOTEL\
MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv\
b3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj\
ca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM\
9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw\
IFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6\
VOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L\
93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm\
jgSubJrIqg0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC\
AYYwHQYDVR0OBBYEFIQYzIU07LwMlJQuCFmcx7IQTgoIMA0GCSqGSIb3DQEBCwUA\
A4IBAQCY8jdaQZChGsV2USggNiMOruYou6r4lK5IpDB/G/wkjUu0yKGX9rbxenDI\
U5PMCCjjmCXPI6T53iHTfIUJrU6adTrCC2qJeHZERxhlbI1Bjjt/msv0tadQ1wUs\
N+gDS63pYaACbvXy8MWy7Vu33PqUXHeeE6V/Uq2V8viTO96LXFvKWlJbYK8U90vv\
o/ufQJVtMVT8QtPHRh8jrdkPSHCa2XV4cdFyQzR1bldZwgJcJmApzyMZFo6IQ6XU\
5MsI+yMRQ+hDKXJioaldXgjUkK642M4UwtBV8ob2xJNDd2ZhwLnoQdeXeGADbkpy\
rqXRfboQnoZsG4q5WTP468SQvvG5\
-----END CERTIFICATE-----\n"};

const char certificate_pem_crt[]={"-----BEGIN CERTIFICATE-----\n\
MIIDWjCCAkKgAwIBAgIVALVR2ZograNlNzo5up8VwY3c7p0yMA0GCSqGSIb3DQEB\
CwUAME0xSzBJBgNVBAsMQkFtYXpvbiBXZWIgU2VydmljZXMgTz1BbWF6b24uY29t\
IEluYy4gTD1TZWF0dGxlIFNUPVdhc2hpbmd0b24gQz1VUzAeFw0yMDA3MzAwMTEw\
MTRaFw00OTEyMzEyMzU5NTlaMB4xHDAaBgNVBAMME0FXUyBJb1QgQ2VydGlmaWNh\
dGUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDXfzdcs2j8FKxD9Mtn\
QQUT6fFd8d0xeqRYkuhMpyk960uvdiI5tE2+/e6PpqzVN80guD3aQIFUUnyLn3/W\
9dqrPXvdlbEFKJT2+nINg4k91wliIkhD93ppiMOUWEuN/Dk6xU/dodbLpCpDQl7e\
ja1sS1Asu4158P6bcYqotRl9m671YI+doOgUbUKxg/hxoln47UWHftqYOpN49fQt\
XMCd7VmL6NVwmjg5ucMdZGZdEb+Egu0iK2YWtzb34K7S4vOtf4tq90Bmku7XkpeW\
uFynrNvdpA0daSbvkh+qCQ1y+5xKl6qEyVnscBZF/lwknFvD1lweG3Ykpw5TB3EN\
dK4FAgMBAAGjYDBeMB8GA1UdIwQYMBaAFDlm3G0/rHBo/P1EvUn6VEPgS7vnMB0G\
A1UdDgQWBBR9FVNNNXzOILM7bOldtcYFSk4OFjAMBgNVHRMBAf8EAjAAMA4GA1Ud\
DwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAQEAk46jKzVS+mEc/pljwEC0/ejx\
7rrxca8dCAQ7QhQAL7cTcELdZGXAJHqSHIAj/9faRaG0CbT4Cgq0M90Xs2U8bivE\
yZIsm7aj4CJ8r43uxfZvSh3W6Nx0lRQdgS72iVNhH3EyxkLIiSlLMB4CqErQow7Y\
t0q+3GCES6BzGnQvrMEoWsUp6SpGNhykgAoGBFjW2k59rPsNILnhWlOE05CrGTCO\
53KH8JpFy4GhxJ1F6OhZU0ixya0dBuxQs5KNvs10N/6mGE+pNPTQDBgJph07L4SU\
j+bVFDmUQ8bwDxSDL9TSSLUKFJpfp/pgDD5UyQ6RXAoblaogjJijAOJU2/4QKw==\
-----END CERTIFICATE-----\n"};

const char private_pem_key[]={"-----BEGIN RSA PRIVATE KEY-----\n\
MIIEpQIBAAKCAQEA1383XLNo/BSsQ/TLZ0EFE+nxXfHdMXqkWJLoTKcpPetLr3Yi\
ObRNvv3uj6as1TfNILg92kCBVFJ8i59/1vXaqz173ZWxBSiU9vpyDYOJPdcJYiJI\
Q/d6aYjDlFhLjfw5OsVP3aHWy6QqQ0Je3o2tbEtQLLuNefD+m3GKqLUZfZuu9WCP\
naDoFG1CsYP4caJZ+O1Fh37amDqTePX0LVzAne1Zi+jVcJo4ObnDHWRmXRG/hILt\
IitmFrc29+Cu0uLzrX+LavdAZpLu15KXlrhcp6zb3aQNHWkm75IfqgkNcvucSpeq\
hMlZ7HAWRf5cJJxbw9ZcHht2JKcOUwdxDXSuBQIDAQABAoIBAQCnj9ztcPeuIyj7\
wkmy5OTc4ihzAxEaWyGVWc3VZJl18xKrwXDFa8SUQQERo+l59WTED17Q6R1nAqij\
LIeMDylTw4AgAThfKXoDPSQYC/JYKm+6ZavJZZJCozxoietd4QRjBW+fhyrst57B\
I8d+x61Uqo8R6VgNvG1NUxEdM4w5lLo6G5Nex1OnLBTYh9fY9dhBqLvhsG7joHZ8\
HR7l1xVLMQZNkf7UI1APeKqHemyfB7AwlVpWo99/xgqY7mLNP5YrmkTm06QnssDo\
C8kmpAhmMSvZmjwAB45MQtmWxFOie0mEeiUBn69a1eiJAVANy8SY7BSPmENWHrAQ\
xSnN3CUBAoGBAO7C46cRFXnG4SJFxFjsrtU/fco/RsYzQPAfGbpmJF7GkNgw+kPz\
AV9VbizpAUePtn2ibLup4WvXs4T9/qWHO8GoM3FMaraH2TFXdD9rSdrb+N0mJ/wi\
TiJSg7jW79gzsu+TFgf5Jrl+jWpSWCZNq1Y1x/42hMttMysbhCASl6xFAoGBAOcO\
Utzz4KelNNDJujnPw9KnVdfbEZcx33MCtkbqTOsORfJWy8My7MQpB7joQlNRLOcv\
U9qXSfEQkCZExUHWp8vPAnFavp6PixUk3ZQdXAjs94HvfisP9LYI18Z4w4Coerw9\
tv0ZDCS5b0qvMVrfloyC/uQ9E6pjXeSi4I6uJHbBAoGBALNim5YPANqgsM+GKXJC\
SU0QydqlVfBd28FNLJBeY58Ngw/bJHze274buo5ldb+lWw/jc9w/U40p38fg6WzG\
QQBL9nJ+XoLLaERpF376hd+4e670FwCZaajh4/OBEWyX0y2qjdfpus2NJoSmX3JP\
0pYQDDWUEougfNw7bTaHoYsdAoGBANY9Ksoi+1iWz50Uny8BnWIStH78apgVr0m1\
5wtkLsP4rRSiNDcfXfgYz0c9XFpit075TDgv9WinYfGJ7Jk6jsVkgbBXYs4k7OJD\
F41Bl9fS2UBKr2MAXXf4RRKLYUNHdN5cHvMZKXBX3ICUZyAKl05cHDnHBBgGIMZh\
2/OQNtFBAoGAVzuCQ8MpWDkk+Uh/qLIuz9u82YV7o8Z+ym8QZqIGcEAqnte5bbr6\
WOmfeu/QJojPm+vKT82+S6lFQmK25PqmYi8L+wnFpvOp6NMEqunhSS/AZaCVZ2gy\
agwSeeNiMbTCXZMmxVoSMpJi7IQ/65cg+gGTqp2wol+IVZIKhHH33iw=\
-----END RSA PRIVATE KEY-----\n"};






int16_t y[10];
 int16_t x=0;
int status = WL_IDLE_STATUS;
int tick=0,msgCount=0,msgReceived = 0,tick1=0;
char payload[512];
char rcvdPayload[512];
uint8_t data1[4] = {41,42,43,44};
uint8_t data2[32];
void mySubCallBackHandler (char *topicName, int payloadLen, char *payLoad)
{
    strncpy(rcvdPayload,payLoad,payloadLen);
    rcvdPayload[payloadLen] = 0;
    msgReceived = 1;
}

// include the library:
#include <spartan-edge-esp32-boot.h>
#include "ESP32IniFile.h"

// initialize the spartan_edge_esp32_boot library
spartan_edge_esp32_boot esp32Cla;

const size_t bufferLen = 80;
char buffer[bufferLen];
char buffer1[bufferLen];
// the setup routine runs once when you press reset:

int16_t re()
{  
  int16_t *x;
  uint8_t da[2];
  SeaTrans.read(0, da,2 );
  x=(int16_t*)data2;
  return *x;
}
int wave(int16_t y)
{
  int16_t t=re();
  if(t>y)
  return 1;
  else if(t<y)
  return 2;
  else
  return 0;
}
void setup()
{
  // initialization 
  esp32Cla.begin();

  // check the .ini file exist or not
  const char *filename = "/board_config.ini";
  IniFile ini(filename);
  if (!ini.open()) {
    Serial.print("Ini file ");
    Serial.print(filename);
    Serial.println(" does not exist");
    return;
  }
  Serial.println("Ini file exists");

  // check the .ini file valid or not
  if (!ini.validate(buffer, bufferLen)) {
    Serial.print("ini file ");
    Serial.print(ini.getFilename());
    Serial.print(" not valid: ");
    return;
  }

  // Fetch a value from a key which is present
  if (ini.getValue("Overlay_List_Info", "Overlay_Dir", buffer, bufferLen)) {
    Serial.print("section 'Overlay_List_Info' has an entry 'Overlay_Dir' with value ");
    Serial.println(buffer);
  }
  else {
    Serial.print("Could not read 'Overlay_List_Info' from section 'Overlay_Dir', error was ");
  }

  // Fetch a value from a key which is present
  if (ini.getValue("Board_Setup", "overlay_on_boot", buffer1, bufferLen)) {
    Serial.print("section 'Board_Setup' has an entry 'overlay_on_boot' with value ");
    Serial.println(buffer1);
  }
  else {
    Serial.print("Could not read 'Board_Setup' from section 'overlay_on_boot', error was ");
  }

  // Splicing characters
  strcat(buffer,buffer1);
  
  // XFPGA pin Initialize
  esp32Cla.xfpgaGPIOInit();

  // loading the bitstream
  esp32Cla.xlibsSstream(buffer);
  Serial.begin(115200);
  SeaTrans.begin();
  //SeaTrans.write(0, data1, 4);
  //SeaTrans.read(0, data2, 4);
  //Serial.printf("%d %d %d %d\r\n",data2[0],data2[1],data2[2],data2[3]);
  delay(2000);

    while (status != WL_CONNECTED)
    {
        Serial.print("Attempting to connect to SSID: ");
        Serial.println(WIFI_SSID);
        // Connect to WPA/WPA2 network. Change this line if using open or WEP network:
        status = WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

        // wait 5 seconds for connection:
        delay(5000);
    }

    Serial.println("Connected to wifi");

    if(hornbill.connect(HOST_ADDRESS,CLIENT_ID,aws_root_ca_pem,certificate_pem_crt,private_pem_key)== 0)
    {
        Serial.println("Connected to AWS");
        delay(1000);

        if(0==hornbill.subscribe(TOPIC_NAME,mySubCallBackHandler))
        {
            Serial.println("Subscribe Successfully");
        }
        else
        {
            Serial.println("Subscribe Failed, Check the Thing Name and Certificates");
            while(1);
        }
    }
    else
    {
        Serial.println("AWS connection failed, Check the HOST Address");
        while(1);
    }

    delay(2000);
  
}

void loop()
{
  uint8_t i;

  unsigned long te=millis()+10000;

  int count=0;
  int nstate=0;
  int cstate=0;

  x=re();
  while(millis()<te)//计算十秒内摇摆次数
  {delay(5);
  nstate=wave(x);
  if((nstate==1)&&(cstate!=1))
  {count++;}
  if((nstate==2)&&(cstate!=2))
 {count++;}
  cstate=nstate;}
        SeaTrans.read(0, data2, 16);
         sprintf(payload, "{\
    \"Temprature\": \"%.2x%.2x\",\
    \"Attitude_angle_data\":{\
        \"X\":\"%.2x%.2x\",\
        \"Y\":\"%.2x%.2x\",\
        \"Z\":\"%.2x%.2x\"\
    },\
    \"Accelaration_data\": {\
        \"X\":\"%.2x%.2x\",\
        \"Y\":\"%.2x%.2x\",\
        \"Z\":\"%.2x%.2x\"\
    }\
    \"counst\":\"%d\"\
}", data2[1], data2[0], data2[3], data2[2], data2[5], data2[4], data2[7], data2[6], data2[9], data2[8], data2[11], data2[10], data2[13], data2[12],count);
        if(hornbill.publish(TOPIC_NAME,payload) == 0)
        {        
            Serial.println("Publish successfully!");
            Serial.println(count);
        }
        else
        {
            Serial.println("Publish failed!");
        }
    
    msgReceived = 0;
}

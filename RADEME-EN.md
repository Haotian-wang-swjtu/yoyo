# yoyo 
English|[中文](https://github.com/Haotian-wang-swjtu/yoyo/blob/master/README.md)
 > This is a summer school internship.
 > 
 > 2020 New Engineering Alliance -Xilinx Summer School Project
 
 ### Inctroduction
 
 
 ##### Project introduction
 
 
 Using the software：`VIVADO 2018.3`; `Arduino IDE`;
 
 Programming language： `Verilog HDL`;
 
 The SEA board,: `Spartan 7`；
 
 Cloud platform：`AWS IOT`；(The account is an educational resource account provided by the summer school）
 
 The name of the team：`一个小队`；
 
 Introduction：This project is a connection cloud project based on 'FPGA'. The data read by the onboard gyroscope is uploaded to the 'AWS IOT' platform through the Arduino serial port. The board first successfully reads the data collected by the onboard 'gyroscope', and then connects it to the computer through the 'Type -- C' serial port. Through the Arduino serial port monitor, the data input of the product can be seen successfully. Then connect to the corresponding AWS IoT through the 'Wifi' connection setting, and successfully see the corresponding data in the theme module; The idea of combining with the web side was carried out later, but was not completed due to time problems。
 
 
 ---
 
 ##### Diagram of the project
 
 
 > The overall structure of the project components
 
![Diagram of the project](框图.png)



---
 
 
 ##### The project content
 
 
 - State data collected by the onboard Gyroscope obtained two 'Temperature data', six 'Gyroscope data', and six 'Magnetometer data', a total of 14 data。
 - The board transmits the collected data to the Arduino serial port of the computer through 'Type - C'。
 - Arduino connects' SEA Board ', 'Wifi', 'AWS'。
 - The Arduino connects to 'AWS IoT' through the network and transfers the uploaded data to IoT cloud disk。
 - Using 'AWS' cloud 'test' to successfully see the returned data。
 
  ![count](计数.gif)
 ![Data is read](Gyro_一个小队)
 
 ---
 ---
 
 
 ### change log
 
 
 ##### v.10.15
  - The problem that data cannot be collected correctly is solved。
  - Updated the upload cloud structure。
 

/*
 * Project: Kinetic | Bluetooth-Bridge Motor Control System
 * Author: Akram Ait-Darhem
 * Target: Arduino Uno/Nano + L298N + HC-05
 */

// --- Pin Definitions ---
#define MOTOR_PWM_PIN 5   // Speed Control (ENA)
#define MOTOR_IN1     8   // Direction A
#define MOTOR_IN2     7   // Direction B

// --- Constants ---
const int MIN_TORQUE_SPEED = 75; // Minimum PWM to overcome motor friction

void setup() {
  Serial.begin(9600); 
  
  pinMode(MOTOR_PWM_PIN, OUTPUT);
  pinMode(MOTOR_IN1, OUTPUT);
  pinMode(MOTOR_IN2, OUTPUT);

  emergencyStop(); // Safety first: ensures motor is off on startup
}

void loop() {
  if (Serial.available() > 0) {
    char command = Serial.read();
    processCommand(command);
  }
}

void processCommand(char cmd) {
  switch (cmd) {
    case '0': emergencyStop(); break;
    case '1': updateMotor(MIN_TORQUE_SPEED); break;
    case '2': updateMotor(135); break;
    case '3': updateMotor(195); break;
    case '4': updateMotor(255); break;
    default:  break; // Ignore noise
  }
}

void updateMotor(int speed) {
  digitalWrite(MOTOR_IN1, HIGH);
  digitalWrite(MOTOR_IN2, LOW);
  analogWrite(MOTOR_PWM_PIN, speed);
}

void emergencyStop() {
  digitalWrite(MOTOR_IN1, LOW);
  digitalWrite(MOTOR_IN2, LOW);
  analogWrite(MOTOR_PWM_PIN, 0);
}
int upChirpTime = 20000;  // in microseconds
int downChirpTime = 20000;  // in microseconds
int sampleRate = 48000;  // in Hertz

// INPUT and OUTPUT pins as defined by PCB hardware.
// DO NOT MODIFY
const int TRIG_PIN = 3; // Oscilloscope trigger output Pin
const int RAMP_PIN = A0; // Arduino Ramp output Pin
const int PROG_PIN = 2; // Pin goes to HIGH to indicate this program was successfully loaded
const int COLLECT_PIN = 5; // Pin to indicate whether or not in Collect Data mode 

const int ADC_IN_PIN = A1; // input Pin, takes Radar input signal
const int CHIRP_PIN=4; // Pin reads the hardware switch's state, if HIGH -> send out ramp samples, if LOW send out CW

int chirp = 1; // Variable to indicate whether chirp is on or off. Initialize chirp to be high = 1 -> output the ramp, LOW = 0 -> output CW
int collect = 1; // Variable to indicate whether to collect data or not.  Initialize collect to be true.

volatile int sIndex;  // Tracks the points in Up- and Down-Chirp array
volatile int dataIndex;  // Tracks the points in Data Received array 
volatile int printIndex;  // Tracks points to print aka Serial Write the data in received array 
int upChirpSampleCount = sampleRate * upChirpTime * 1e-6; // Number of samples in the Up-Chirp ramp
int downChirpSampleCount = sampleRate * downChirpTime * 1e-6; // Number of samples in the Down-Chirp ramp
int sampleCount = upChirpSampleCount + downChirpSampleCount;  // Total number of samples
int *rampSamples; // Array to store ramp points
short *recSamples; //Array to store received signal points



void setup() {
  // put your setup code here, to run once:
  
  // set up serial baud rate
  Serial.begin(500000); // baud rate, the serial data transfer speed to PC
  
  // set up input and output pins  
  pinMode(TRIG_PIN, OUTPUT);  // Defines TRIG_PIN to be an Output
  pinMode(CHIRP_PIN, INPUT_PULLUP);  // Defines CHIRP_PIN as an input, and uses pull-up if value is floating to ensure no ambiguity in value
  pinMode(COLLECT_PIN, INPUT_PULLUP);   // Defines COLLECT_PIN as an input, and uses pull-up if value is floating to ensure no ambiguity in value
  pinMode(PROG_PIN, OUTPUT); // Defines PROG_PIN to be an Output
  digitalWrite(PROG_PIN,HIGH); // Write 3.3V to PROG_PIN to indicate this program was successfully loaded.
  // set up analog write and read bit resolution
  analogWriteResolution(10); // in bits, maximum write resolution
  analogReadResolution(12);  // in bits, set the analog data read resolution to be 12 bits (4095 discrete values)
  
  // configure microcontroller for rapid ADC conversion
  analogRead(ADC_IN_PIN); //Starts setting up the ADC
  ADCdisable();  // First, disable the ADC register to be able to reconfigure it 
  ADCconfigure();  // Set it up with prescaler settings for faster ADC functionality
  ADCenable();  // Enable it with these new settings

  // configure microcontroller trigger pin for faster response
  REG_PORT_DIRSET0 = PORT_PA09;  //Set SAMD register to directly define PA09 (D3) as an output; this is for a faster response in the TRIG_PIN output 

  // pre-allocate buffers for ramp samples and receive samples
  rampSamples = (int *) malloc(sampleCount * sizeof(int)); // Allocate the buffer where the ramp samples for one period are stored
  recSamples = (short *) malloc(sampleCount * sizeof(short)); // Allocate the buffer where the recieved samples for one period are stored

  // generate the Up- and Down-Chirp ramp
  genRamp(sampleCount, upChirpSampleCount, downChirpSampleCount); // Calls function to calculate ramp values and store into memory

  // configure interrupt routines
  tcConfigure(sampleRate); // Set up the Timer Counter based off of the sample rate.  Ensures precise timing of signal sampling.
  tcStartCounter(); // Enables Timer/Counter and waits for it to be ready
  
}



// loop() function does the following:
// Checks the input value of the CHIRP_PIN and COLLECT_PIN to see what mode the radar is in.  
// Output HIGH on TRIG_PIN during upChirpTime and LOW during DownChirpTime on PA09=Pin 3 to allow monitoring on oscilloscope. PA## to Pin translation obtained from SAMD Arduino schematic.
// Write the Radar's received data over the serial port in binary format.

void loop() {
  // put your main code here, to run repeatedly:

  // check for hardware state changes from switches
  chirp = digitalRead(CHIRP_PIN); // Read CHIRP_PIN to see if Radar is in Ranging/SAR mode or Doppler
  collect = digitalRead(COLLECT_PIN); // Read COLLECT_PIN to see if Radar is in Collecting data or not

  // reset all indexes 
  sIndex = 0;   // Sample Index counter: set to zero to start from beginning of waveform
  dataIndex=0;  // Data Index counter: set to zero.
  printIndex=0; // Print Data Index counter: set to zero to start from beginning 

  // step through the indexes in the Up- and Down-Chirp rampSamples arrays
  while (sIndex < sampleCount-1)  // For one period of rampSamples (Up- and Down-Chirp)
  {
    // TRIG_PIN handler
    if(sIndex<upChirpSampleCount){    // If the Index is during the Up-Chirp sample count...
      REG_PORT_OUTSET0 = PORT_PA09;  // Set TRIG_PIN HIGH to be able to measure on oscilloscope the Up-Chirp duration 
    }
    else{                             // If the Index is not during the Up-Chirp sample count...
      REG_PORT_OUTCLR0 = PORT_PA09;   // Set TRIG_PIN LOW to be able to measure on oscilloscope the Down-Chirp duration 
    }

    // if in Range/SAR mode, insert a flag in the serial datastream when upChirp is complete; otherwise write received data to the serial datastream
    if(chirp==1 && collect ==1){      // If hardware mode is switched to Ranging/SAR and Serial Enable
      if(printIndex==upChirpSampleCount+1){            // At sample count which is the first one after the Up-Chirp completes (this is 961 for 20ms upChirp at 48ksps)
        Serial.write(4500/256);  // Write this specific value (4500) as a flag to indicate the end of Up-Chirp data
        Serial.write(4500%256);  // Arduino Serial.write sends data in binary format as two bytes
      }
      else{                      // write the received data at the printIndex
      //For speed, rather than sending ASCII integers, and since Serial.write only writes one byte at a time, need to break the 16-bit into two 8-bit bytes, sent separately as a higher order byte and lower order byte.  
        Serial.write((recSamples[printIndex] >> 8) & 15);   // Send the Radar's Received Data to PC via logical shift of 8 bits anded with 15, equivalent to divide by 2^8=256
        Serial.write(recSamples[printIndex] & 255); // logical operator equivalent to modulo 256.  Done with logical operators to ensure unsigned arithmetic.
      }
       printIndex++; 
    } 
    else{     // When the Hardware mode is in Doppler...
      // do nothing, let Timer Interrupts handle to keep clocking precision
    }
  }   // End of while loop for one period (i.e. one up-chirp and one down-chirp)
}  // End of loop() function




// genRamp function: Generates a ramp of values (up and down ramp) to drive the VCO and stores them in the rampSamples array.
// The input argument is the total number of samples (sCount), number of samples during Up-Chirp (sCountUp), and number of samples during Down-Chirp (sCountDown)

void genRamp(int sCount, int sCountUp, int sCountDown) {
 
  for (int i = 0; i < sCount; i++) { // Loop to calculate the ramp based on sample count
    if (i < sCountUp) {
      rampSamples[i] = (int)(1023.0 / sCountUp * i); // for 10-bit DAC
    }
    else {
      rampSamples[i] = (int)(-1023.0 / sCountDown * (i - sCountUp) + 1023); // for 10-bit DAC
    }
  }

}  // End of genRamp function



// Timer/Counter (TC) functions are derived from http://forcetronic.blogspot.com/2015/10/arduino-zero-dac-overview-and-waveform.html and https://github.com/arduino-libraries/AudioZero/blob/master/src/AudioZero.cpp

// tcConfigure function configures the timer counter (TC) to generate output events at the sample frequency.
// Function configures the TC in Frequency Generation mode, with an event output once each time the sample frequency period expires.
void tcConfigure(int sampleRate)
{
  
  GCLK->CLKCTRL.reg = (uint16_t) (GCLK_CLKCTRL_CLKEN | GCLK_CLKCTRL_GEN_GCLK0 | GCLK_CLKCTRL_ID(GCM_TC4_TC5)) ;  // enable GCLK for TC4 and TC5 (timer counter input clock)
  while (GCLK->STATUS.bit.SYNCBUSY);
  tcReset();                                         //reset TC5
  TC5->COUNT16.CTRLA.reg |= TC_CTRLA_MODE_COUNT16;   // set Timer counter Mode to 16 bits
  TC5->COUNT16.CTRLA.reg |= TC_CTRLA_WAVEGEN_MFRQ;   // set TC5 mode as match frequency
  TC5->COUNT16.CTRLA.reg |= TC_CTRLA_PRESCALER_DIV1 | TC_CTRLA_ENABLE;  // set prescaler and enable TC5
  TC5->COUNT16.CC[0].reg = (uint16_t) (SystemCoreClock / sampleRate - 1);  // set TC5 timer counter based off of the system clock and the user defined sample rate or waveform
  while (tcIsSyncing());  // wait until TC5 is done syncing

  // Configure interrupt request
  NVIC_DisableIRQ(TC5_IRQn);
  NVIC_ClearPendingIRQ(TC5_IRQn);
  NVIC_SetPriority(TC5_IRQn, 0);
  NVIC_EnableIRQ(TC5_IRQn);
  
  // Enable the TC5 interrupt request
  TC5->COUNT16.INTENSET.bit.MC0 = 1;
  while (tcIsSyncing());  // Wait until TC5 is done syncing
  
}   // End of tcConfigure function


// tcIsSyncing function used to check if TC5 has completed syncing.
// Function returns true when it is done syncing.
bool tcIsSyncing()
{
  return TC5->COUNT16.STATUS.reg & TC_STATUS_SYNCBUSY;
} 


// tcStartCounter function enables TC5 and waits for it to be ready
void tcStartCounter()
{
  TC5->COUNT16.CTRLA.reg |= TC_CTRLA_ENABLE;  // Set the CTRLA register
  while (tcIsSyncing());  // Wait until sync'd
} 


// tcReset function resets TC5
void tcReset()
{
  TC5->COUNT16.CTRLA.reg = TC_CTRLA_SWRST;
  while (tcIsSyncing());
  while (TC5->COUNT16.CTRLA.bit.SWRST);
} 

// tcDisable function disables TC5
void tcDisable()
{
  TC5->COUNT16.CTRLA.reg &= ~TC_CTRLA_ENABLE;
  while (tcIsSyncing());
}


// INTERRUPT HANDLER

// TC5_Handler function controls what happens during the Interrupts.  Function updates the DAC output.
// It does these tasks at every waveform sample point.

void TC5_Handler (void)
{
  // if in Doppler mode
  if(chirp == 0 && collect == 1){               // If chirp pin is reading = LOW -> chirp is off (Doppler Mode), send out CW and read in ADC_IN and serial print out that data
    analogWrite(RAMP_PIN,512);                  // Write this single value to the RAMP_PIN to output a CW ouput to VCO.  (512 = 1024/2 = mid-range of ramp values for CW)
    // sample the received analog signal
    recSamples[sIndex]=analogRead(ADC_IN_PIN);  // Record the Radar's received input into recSamples.  
    Serial.write((recSamples[sIndex] >> 8) & 15);   // Immediately write this received data over serial port to PC.  TRIG_PIN will show longer period (~38.4msec positive pulse and ~38.4msec negative pulse)
    Serial.write(recSamples[sIndex] & 255);      // because Serial.write of every single received value (rather than just values received during Up-Chirp).
  }
  // if in Range/SAR mode
  else if (chirp == 1 && collect ==1){           // If chirp is HIGH...
    analogWrite(RAMP_PIN, rampSamples[sIndex]);  // then send out the Up- and Down ramp values to VCO.
    // At the first index of the ramp, insert a flag in the serial datastream (when Up-Chirp begins)
    if(sIndex == 0){                            // If this is the first value in the Up-Chirp...
      Serial.write(5000/256);                   // Write this specific value as a flag to indicate beginning of new pulse.
      Serial.write(5000%256); 
    }
    // sample the received analog signal    
    recSamples[dataIndex] = analogRead(ADC_IN_PIN); // Record the Radar's received data into an array.
    dataIndex++;
  }
  // otherwise (i.e. collect is disabled) send zeros in serial datastream (i.e. no received data)
  else{                 // If Collect status is 'off', write ZERO over serial port.
    Serial.write(0.0);
  }
  sIndex++;             // This interrupt routine occurs for every sample point. 
  TC5->COUNT16.INTFLAG.bit.MC0 = 1;  // Clears interrupt flag.

}



// ADC functions are derived from https://github.com/arduino-libraries/AudioFrequencyMeter/blob/master/src/AudioFrequencyMeter.cpp and modified for this application

// ADCconfigure function configures the ADC prescaler clock for faster ADC conversion. 
// It controls how many microcontroller clocks it takes for every ADC conversion for this bit resolution at our sampling frequency. This must occur faster than the interrupts that occur at the sampling frequency. 
// DO NOT MODIFY
void ADCconfigure()
{
  ADC->CTRLB.bit.RESSEL = ADC_CTRLB_RESSEL_12BIT_Val;         // sets ADC conversion result resolution.  See section 33.8.5 of Atmel-42181-SAM-D21 Datasheet. 
  while (ADCisSyncing());

  ADC->CTRLB.bit.PRESCALER = ADC_CTRLB_PRESCALER_DIV16_Val;   // Divide the SAMD Clock by 16 -> 48MHz/(16 prescaler)/(16 sample length)/(2 Nyquist) -> ~100kHz ADC sample rate
  while (ADCisSyncing());

  ADC->SAMPCTRL.reg = 0xF;                                    // Controls the ADC sampling time, depending on Prescaler value. F=sample time length of 16, See section 33.8.4 of Atmel-42181-SAM-D21 Datasheet.
  while (ADCisSyncing());

  void ADCsetMux();         // Configure the ADC input pin. 
}



// ADCisSyncing function checks if synching is complete.
bool ADCisSyncing()
{
  return (ADC->STATUS.bit.SYNCBUSY);
}


// ADCdisable function disables the ADC.
void ADCdisable()
{
  ADC->CTRLA.bit.ENABLE = 0x00;            // Disable ADC
  while (ADCisSyncing());
}

// ADCenable function enables the ADC.
void ADCenable()
{
  ADC->CTRLA.bit.ENABLE = 0x01;            // Enable ADC
  while (ADCisSyncing());
}

// ADCsetMux function configures the ADC input pin to read positive voltages.
void ADCsetMux()   
{
  while (ADCisSyncing());
  ADC->INPUTCTRL.bit.MUXPOS = g_APinDescription[ADC_IN_PIN].ulADCChannelNumber; // Selection for the positive ADC input pin
}







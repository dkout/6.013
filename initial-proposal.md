% 6.013 Initial Proposal
% Andres Erbsen; Justin Graves; Dimitris Koutentakis
% \today

# Inductive RFID range experiments

MIT has these "wonderful" RFID tags that we need to tap to enter campus spaces.
Wouldn't it be cool if we could hang one off our backback, and get in the door
without needing to look for a piece of plastic in our wallets? Thus, we would
set forth to investigate the limits of read range of a inductive RFID system
such as MIT-s. 

Each tag consists of a RLC circuit tuned to 125khz, with the inductor coil
acting as the antenna. The magnetic wave broadcast by the reader gets picked up
by the tag's coil and acts both as a power source and an antenna. The tag sends
information back by modulating its resistance, which shows up as a voltage amplitude
change on the reader's RLC circuit.

We would use build a RFID reader and measure how its read range changes with
different (coil) antennas, transmit powers, and relative positionings of the tag
and the antenna. As a stretch goal, we would characterize the effect of
alternative channel materials such as water (simulating a human), books, and
whatever else might be between a RFID reader and a tag in real life.

# transmit information

- can we measure the signal quality without VNA
- how do obstacles affect signal quality?
  -   complex S(\lambda) matrix
  -   eye diagram
  -   BER
- how can we improve the signal using antenna design?

# metal detector

Our group would use RADAR to analyze reflected power and transmitted
power from various metals in an attempt to classify their intrinsic
properties such as permittivity and permeability. Once we quantify
such metals we will use the data to sweep a room to find a particular
metal we are interested in and define its distance. We will also
characterize the penetration depth of each metal.


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
power from various materials in an attempt to classify their intrinsic
properties such as permittivity and permeability. Once we have
collected data for common materials, we will use the data to, for
example, sweep the walls of a room to find a metal objects are
interested in and determine their size and distance.

Ideally, we would use our model of material properties to
automatically classify the signal as "metal" or "not metal", and have
our radar announce it in real time. However, the primary goal of this
project is to great the model, building the interactive functionality
might make for a nice demo but is probably less interesting.

We expect to be able to reuse the radar equipment for the majority of
this project, most of the work would be in characterization and
classification of materials based on their properties.
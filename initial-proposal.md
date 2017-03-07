---
title: 6.013 Initial Proposal
author: Andres Erbsen; Justin Graves; Dimitris Koutentakis
date: \today
header-includes:
	\usepackage{geometry}
	\usepackage{graphicx}
---

#1. Information Transmission Over Different Channels

For this project we aim to build a radar that sends information and characterizes a material in two main domains: One provide a scattering parameter matrix and two see how that affects bit error rate or information transmission through that medium. 

The radar would have two configurations in order to produce those results. As seen in sketch (a) the first configuration would be the two antennas facing each other. In this configuration, we would put the material in between antenna and receiver in order to measure $S_{11}$ and the BER. 

The second configuration (sketch b) would have the antennas pointing the same way in order to measure $S_{21}$. We can either use three separate antennas to conduct those experiments or allow degrees of freedom in order to be able to move the two antennas into whichever configuration we need. 
For the measurement of $S_{11}$ and $S_{21}$ we would have to measure the power received in each of the configurations and then take the ratio to the power of the signal sent. In order for this to work properly, we will first have a “calibration mode” in order to account for the free space loss. 
In order to measure the Bit Error Rate, we will implement some sort of information transmission. We would start by modulating the information we want to send and then apply the same method on the received signal in order to demodulate the signal. By comparing the sent and the received signal we will then do a Bit Error Rate detection.
This will allow us not only to characterize various materials, but also to see what types of materials are best for sending information at different frequencies. 

\includegraphics[height=5cm]{data-a}
\hfill
\includegraphics[height=5cm]{data-b}
\hfill
\includegraphics[height=5cm]{along}

#2. Inductive RFID Range Experiments

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

\includegraphics[height=4cm]{rfid}
\hfill
\includegraphics[height=4cm]{metaldetect}


#3. Metal Detector

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

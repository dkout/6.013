---
title: 6.013 Project Proposal\linebreak
	Design and Characterization of Microstrip Filters
author: 
	- Andres Erbsen
	- Justin Graves
	- Dimitris Koutentakis
date: \today
header-includes:
	\usepackage[margin=1in]{geometry}
	\usepackage{graphicx}
---

# Overview

We want to learn to design, build and analyze microstrip filters. After all,
what could be cooler than a useful circuit with no lumped components.
Concretely, we plan to design and build two 2.4GHz band-pass filters using
microstrips alone, and measure the two-port S-parameters of both of them. The
designs will be optimized for a compromise of build simplicity and high $Q$.

# Microstrip Filter Designs

## Lumped Circuit Analog

For our first filter design we will use the concept that we learned in class: at
high frequencies transmission line stubs can be left open or shorted to emulate
discrete lumped elements: inductors and capacitors. We plan to simplify our
design by keeping the length of our stubs to $\frac{\lambda}{8}$, then are stubs
will have the absolute-value impedance equal to $Z_{0}$. We plan to vary $Z_0$
by changing the width-length ratio of the transmission line, allowing us to emulate lumped
elements of various impedances. A non-tangible goal of this experiment is for us
to gain a more practical, intuitive understanding of how much microstrip
implementation constraints limit the design room for analog filters.

## TEM Resonator

We plan to design and build a bandpass filter based on the TEM resonator
topology presented in the end of lecture 14 and in pset 7 problem 2.

## Implementation Strategy and Risks

Using $\epsilon=2.33$ substrate described in the lab handout, 2.4GHz waves would
have wavelength $\frac{3 \cdot 10^{8}\text{m/s}}{\sqrt{2.33}\cdot 2.4GHz} = 8.2\text{cm}$ -- much more
practical than the values found in the pset. We plan to use that (or similar)
substrate by default, creating traces using copper tape.  However, it is not
obvious that any particular filter design we choose will be implementable using
the tolerances that we can manufacture by hand -- anything below 1mm will be a
point to backtrack and investigate alternative parameter choices. If absolutely
necessary, we can vary the choice of the substrate or operating frequency.
Again, while the project is to build and quantify some filters, we are doing
this to understand what \emph{can} be done, so a negative result is as
informative as a success -- we will just have to make sure that we also get some
of the latter.

# Testing Filters Using Our "Radar"
In order to test that our filters work correctly, as well as make as much use as possible out of the radar we have already built, we plan on using the radar as a basic Vector Network Analyzer.  This VNA will be very similar to what we already have, since we only plan on measuring the S{21} paramater of our filters. S{21} should be enough to tell us if the filters are working as expected. Thus we will not need to complicate further our radar build in order to measure the rest of the S-matrix parameters. 

The main changes we plan to do in order to use the radar to quantify the performance of our filters are summarized below:

Hardware changes:
a) Remove the can-antennas and replace them with regular SMA cables that will be attached to our filters.

Software changes:
a) Remove Doppler operation
b) Edit radar operation so that it scans a range of frequencies and measures how the power at the input at each of the frequencies. The arduino code would then return those arrays that we can use in order to plot how S21 changes depending on the frequency.

Once we implement those changes, we should be on track to verify the performance of the filters.


# Application Ideas

#### WiFi Channel Detection?

It would be really could if we could build a demo where different LED-s would
turn on according to which WiFi channels are in use (using just filters and
amplifiers, no active components). However, after detailed analysis, we believe
that setting this as a goal would be overly ambitious.
The most variant of WiFi, 802.11g, operates (in the US) on 11 evenly-spaced
frequencies from 2.412 to 2.462 GHz. Based on real-world experience, we estimate
the noise level as -90dBm and a "good" signal as -50dBm for the purposes of this
calculation. Thus, if we wanted to detect that channel 1 has no signal even if
channel 11 is getting "full blast" from a nearby WiFi transceiver, our filter
would need to have an attenuation of 40dB = 10000 only a fraction
$\frac{\omega_{11}-\omega_{1}} {\omega} \approx \frac{50}{2500} = \frac{1}{50}$
of the center frequency away from its passband. This seems difficult.

#### WiFi vs GSM

A much simpler version of the same task would be to differentiate GSM (around
900MHz or 1800 MHz) from 2.4GHz WiFi, even though both signals are received on
the same antenna.  However, since we have not learned about antennas yet, we
don't know how to plan this one out. Of course, different phones and cell towers
support different frequencies --  we would first use a software defined radio
receiver to determine which frequency is used for cellular communication by our
test phone, and then build a filter to detect that. Note that while intercepting
GSM data is not necessarily legal, just detecting the presence of a signal (from
our own phone) is fine. For a demo, we might make different LEDs turn on on a
receiver board when the same phone is using cellular data or WiFi.

\includegraphics[height=1.5in]{block-dia.png}

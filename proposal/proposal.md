---
title: 6.013 Project Proposal\linebreak
	Design and Characterization of Stripline Filters
author: 
	- Andres Erbsen
	- Justin Graves
	- Dimitris Koutentakis
date: \today
header-includes:
	\usepackage{geometry}
	\usepackage{graphicx}
---

# Overview

We want to learn to design, build and analyze microstrip filters. After all,
what could be cooler than a useful circuit with no lumped components. We hope
that we will be able to build a system for detecting which WiFi channel (out of
two) is in use with a single antenna, without any lumped-circuit filters or
signal processing.

# Example Filter Design

# Testing Filters Using Our "Radar"
In order to test that our filters work correctly, as well as make as much use as possible out of the radar we have already built, we plan on using the radar as a basic Vector Network Analyzer.  This VNA will be very similar to what we already have, since we only plan on measuring the S{21} paramater of our filters. S{21} should be enough to tell us if the filters are working as expected. Thus we will not need to complicate further our radar build in order to measure the rest of the S-matrix parameters. 

The main changes we plan to do in order to use the radar to quantify the performance of our filters are summarized below:

Hardwear changes:
a) Remove the "can-tennas" and replace them with regular SMA cables that will be attached to our filters.

Softwear changes:
a) Remove Doppler operation
b) Edit radar operation so that it scans a range of frequencies and measures how the power at the input at each of the frequencies. The arduino code would then return those arrays that we can use in order to plot how S21 changes depending on the frequency.

Once we implement those changes, we should be on track to verify the performance of the filters.


# Application to WiFi Channel Detection

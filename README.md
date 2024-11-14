# RippleApp
For detection of Sharp-wave ripple events and comparison of different detection methods

Currently WIP. 

RP_DETECT Method: Uses the Hilbert transform method to analyze the amplitude envelope of the bandpass-filtered local field potential (LFP) signal, isolating oscillations in the ripple frequency range (typically 100-250 Hz, but you can set this range in the app). On the extracted envelope, it identifies potential sharp wave ripples (SWR Events) by detecting segments where the amplitude surpasses a threshold set at a specified number of standard deviations above the mean. Runs individually on all tetrodes and tries to merge events together which occur simultaneously on multiple tetrodes. 

To use:
- Requires matlab 2024b
- Open RippleApp.mlapp. This should open it in the app designer. Press RUN at the top

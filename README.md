# SLFidTrack

A GPU-Assisted fiducial tracking system consisting of AprilTag library integrated with GPUImage library.

The idea is to use the GPU for monochrome thresholding, then passing the result to 
the fiducial tracking/detection library.

This code was demoed at the San Francisco World Maker Faire 2015 in the Atlas Sailed booth.

It was used for tracking of fiducials on the "real world" cubes that were manipulating virtual cubes.

A short video of the system in action:

https://vimeo.com/128336363

You can see the tracking system running on the laptop in front of the "real world" cubes.

The actual demo project is located in GPUImage/examples/Mac/SimpleVideoFilter


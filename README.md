# ruby-vips-riapi : ruby-vips implemetation of riapi

RIAPI (RESTful Image API) is a web service specification for image processing,
see:

https://github.com/riapi/riapi

This repository is attempting to implement this specification using the libvips
image processing library, via the ruby-vips binding:

https://github.com/jcupitt/ruby-vips

## Usage

The 'samples' URI lists the images available for resizing.

> foreman start<br>
> curl localhost:5000/samples

    curiosity.jpg
    jasper.jpg
    siurana.jpg

Accessing an image with RIAPI parameters resizes the image in accordance to the *level 1* specification and returns the path to the result.

> curl jasper.jpg?w=1320&h=320&mode=crop&scale=canvas

    out/jasper.jpg

## Benchmark

The current benchmark runs the main processing routine to scale images of various sizes to 100x100 ... 700x700 pixels. The table shows mean values and standard deviations over 5 runs.

> ruby benchmark/run.rb

     x5            user       system     total      real       
     100 curiosity 0.21(0.03) 1.18(0.23) 1.39(0.23) 1.72(0.31) 
     300 curiosity 0.20(0.04) 1.21(0.02) 1.41(0.04) 1.71(0.05) 
     500 curiosity 0.20(0.03) 1.38(0.04) 1.59(0.05) 1.89(0.04) 
     700 curiosity 0.28(0.01) 1.57(0.08) 1.85(0.08) 2.21(0.11) 
     100 siurana   0.04(0.01) 0.33(0.02) 0.37(0.02) 0.51(0.01) 
     300 siurana   0.05(0.02) 0.51(0.01) 0.56(0.02) 0.72(0.02) 
     500 siurana   0.07(0.03) 0.69(0.03) 0.76(0.04) 0.92(0.01) 
     700 siurana   0.09(0.02) 0.83(0.02) 0.93(0.03) 1.12(0.01) 
     100 jasper    0.01(0.01) 0.15(0.00) 0.16(0.01) 0.26(0.01) 
     300 jasper    0.02(0.01) 0.31(0.01) 0.33(0.02) 0.44(0.01) 
     500 jasper    0.02(0.01) 0.39(0.03) 0.41(0.04) 0.53(0.02) 
     700 jasper    0.01(0.01) 0.47(0.02) 0.49(0.02) 0.62(0.02) 

Image sizes are:

 * curiosity.jpg: 3200x3200
 * siurana.jpg: 1600x1200
 * jasper.jpg: 640x480

## Test suite

There are two sets of tests: functional tests of the rendering engine and unit tests of the layout engine.

The rendering tests perform a number of operations on 'jasper.jpg' and write the output to 'out'.

> ruby test/render.rb

The unit tests are implemented in RSpec and can be found in the 'spec' directory.

> rspec spec/layout-spec.rb

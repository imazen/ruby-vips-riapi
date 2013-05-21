# ruby-vips-riapi : ruby-vips implemetation of riapi

riapi (RESTful Image API) is a web service specification for image processing,
see:

https://github.com/riapi/riapi

This repository is attempting to implement this specification using the libvips
image processing library, via the ruby-vips binding:

https://github.com/jcupitt/ruby-vips

## Usage

foreman start

curl localhost:5000/samples

    curiosity.jpg
    jasper.jpg
    siurana.jpg

curl localhost:5000/benchmark

                        user     system      total        real
    100 curiosity   0.230000   1.080000   1.310000 (  1.593582)
    300 curiosity   0.190000   1.270000   1.460000 (  1.743982)
    500 curiosity   0.240000   1.420000   1.660000 (  1.958624)
    700 curiosity   0.320000   1.590000   1.910000 (  2.263554)
    100 jasper      0.020000   0.150000   0.170000 (  0.272635)
    300 jasper      0.030000   0.360000   0.390000 (  0.505222)
    500 jasper      0.060000   0.550000   0.610000 (  0.770808)
    700 jasper      0.030000   0.580000   0.610000 (  0.786042)
    100 siurana     0.060000   0.320000   0.380000 (  0.514136)
    300 siurana     0.060000   0.510000   0.570000 (  0.724543)
    500 siurana     0.120000   0.680000   0.800000 (  0.989229)
    700 siurana     0.150000   0.910000   1.060000 (  1.281720)

curl localhost:5000/siurana.jpg?width=100\&height=200

    width:  100
    height: 200
    mode:   pad
    scale:  down

# Third-party notices

Selenia's code is licensed under the GNU General Public License v3.0 (see `LICENSE`). The data it ships with comes from other people and keeps its own terms. The app shows the same credits under About → Sources.

## Stars

**HYG database v4.1** by David Nash (astronexus), CC BY-SA 4.0.
https://github.com/astronexus/HYG-Database
`App/Resources/stars.bin` is the same file Astrelia ships, built from HYG by `Tools/build_star_catalog.py` in the [Astrelia repo](https://github.com/pharmacykitty/Astrelia). It's a derivative of HYG and is shared under CC BY-SA 4.0, not the GPL.

## Constellation lines

`App/Resources/constellation_lines.json` comes from **d3-celestial** by Olaf Frohn (https://github.com/ofrohn/d3-celestial), under this license:

```
Copyright (c) 2015, Olaf Frohn
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

## Everything else

- Chiron, Ceres, Pallas, Juno and Vesta orbital elements: NASA/JPL Small-Body Database (public domain).
- House systems, aspects and the Lahiri ayanamsa follow published astrological references; the math is implemented in [AstroPackages](https://github.com/pharmacykitty/AstroPackages), which has its own `NOTICE.md`.
- The interpretation text is written for this project from keyword tables. Nothing is copied from books or licensed corpora, and Swiss Ephemeris isn't used.

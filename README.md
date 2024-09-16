## bbe - binary block editor
bbe program is a sed-like editor for binary files. bbe performs basic byte related
transformations on blocks of input stream. bbe is non-interactive command line tool and
can be used as a part of a pipeline. bbe makes only one pass over input stream.
bbe contains also grep-like features, like printing the filename, offset and block number.
### How to build
GNU autotools and gcc are required to build bbe.

Clone from github and then:
```
cd bbe
autoreconf -is
./configure
make
```

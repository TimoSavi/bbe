## bbe - binary block editor
The bbe program is a sed-like editor for binary files. It performs basic byte-related
transformations on blocks of the input stream. bbe is a non-interactive command-line tool and
can be used as part of a pipeline. bbe makes only a single pass over the input stream.
bbe also provides grep-like features, such as printing the filename, offset, and block number.
### How to build
GNU Autotools and GCC are required to build bbe.

Clone from github and then:
```
cd bbe
autoreconf -is
./configure
make
```

# bbe - Binary Block Editor

`bbe` is a stream editor for binary files, designed as a binary counterpart to the standard Unix `sed` utility. It performs byte-level transformations, replacements, deletions, bitwise operations, and formatting on defined blocks of an arbitrary binary input stream.

Operating as a non-interactive command-line tool, `bbe` makes only a single pass over its input with a constant, minimal memory footprint (~512 KB), making it ideal for processing arbitrarily large binary files, disk images, and pipelines. It also provides grep-like capabilities, such as locating and printing file names, stream offsets, and block indices.

---

## Installation

### Prerequisites
To build `bbe` from source, the following tools are required:
* A C99-compliant C compiler (such as GCC or Clang)
* GNU Autotools (`autoconf >= 2.69`, `automake >= 1.14`, `make`)

### Building from Source

Clone the repository and build:

```bash
git clone https://github.com/TimoSavi/bbe.git
cd bbe
autoreconf -i
./configure
make
```

### Running Tests
To run the automated regression test suite:

```bash
make check
```

### System Installation
To install `bbe` to your system (defaults to `/usr/local/bin`):

```bash
sudo make install
```

To install to a custom directory, pass `--prefix` to `./configure`:
```bash
./configure --prefix=/opt/bbe
make && make install
```

---

## Common Use Cases

`bbe` maps familiar `sed` workflows to binary data:

### 1. Search and Replace in Binary Files
Replace strings or URLs inside compiled binaries, firmware, or disk images. When strings contain slashes, any delimiter (such as `#` or `:`) can be used:
```bash
bbe -e 's#http://old.example.com#https://new.example.com#' binary.elf
```

### 2. Padded In-Place String Replacement
When patching hardcoded paths or strings in compiled binaries, pad shorter strings with null bytes (`\x00`) to preserve the exact original length and avoid corrupting binary offset tables:
```bash
bbe -e "s#/usr/local/lib\x00#/opt/app/lib\x00\x00\x00\x00\x00\x00#" binary.elf
```

### 3. Stripping Fixed-Size Binary Headers
Similar to `sed '1,10d'`, delete a fixed-size header (e.g. 44-byte WAV header or 512-byte boot sector) to extract the raw data payload:
```bash
bbe -b 0:44 -e "D" audio.wav > raw_pcm.bin
```

### 4. Slicing Payloads Between Magic Markers
Similar to `sed -n '/START/,/END/p'`, extract an embedded file or payload between two binary delimiter signatures using `-s` (suppress non-matching stream):
```bash
bbe -b "/\xff\xd8\xff/:/\xff\xd9/" -s firmware.bin > extracted_image.jpg
```

### 5. In-Place Instruction Patching & Zero-Filling
Patch opcodes at a specific offset (e.g. replace a conditional jump with two x86 NOPs `0x90 0x90`):
```bash
bbe -b 0x1000:8 -e "r 2 \x90\x90" program.bin
```
Or zero out sensitive fields (e.g. fill from offset 11 to the end of a 27-byte block):
```bash
bbe -b "/SECRET_KEY=/:27" -e "f 11 \x00" config.dat
```

### 6. Locating Stream Byte Offsets of Signatures
Similar to `sed -n '/pattern/='`, locate all occurrences of a signature and print their stream byte offsets in hexadecimal:
```bash
bbe -b "/\x7fELF/:4" -s -e "d 0 4;F h;A \n" disk.img
```

### 7. In-Place ASN.1 / DER Certificate Modification
Locate an ASN.1 TLV structure (e.g. `countryName` PrintableString tag `\x13\x02` with value `"ES"`) and replace its value with `"FI"` while maintaining a valid DER encoding:
```bash
bbe -b "/\x06\x03\x55\x04\x06\x13\x02/:9" -e "r 7 FI" cert.der > cert_modified.der
```

### 8. Formatting Hex & Combined Hex+ASCII Dumps
Generate a 16-byte formatted hexadecimal dump with stream offsets:
```bash
bbe -b :16 -s -e "F h;p H;A \n" data.bin
```
Or view hexadecimal and ASCII characters side-by-side:
```bash
bbe -b :16 -s -e "F h;p HA;A \n" data.bin
```

### 9. Transliteration & Bitwise Masking
Invert byte values (e.g. swap black and white pixels in a bitmap):
```bash
bbe -e "y/\x00\xff/\xff\x00/" image.pbm
```
Or clear high/parity bits in a serial communication capture:
```bash
bbe -b :1 -e "& \x7f" capture.bin
```

### 10. Demultiplexing Streams into Numbered Files
Similar to `sed 'w file'`, split a binary stream into sequentially numbered files using the `%B` block number specifier:
```bash
bbe -b "/PK\x03\x04/:65536" -s -e "w zip_chunk_%03B.bin" -o /dev/null bundle.bin
```

---

## Documentation & Manual

Complete documentation is available in several formats:
* **PDF Manual:** [doc/bbe.pdf](doc/bbe.pdf) - Complete printable reference manual
* **Man Page:** Run `man bbe` (or view [doc/bbe.1](doc/bbe.1))
* **GNU Info:** Run `info bbe` (or browse Texinfo source at [doc/bbe.texi](doc/bbe.texi))

---

## License

`bbe` is licensed under the GNU General Public License v2 (or later). See the [COPYING](COPYING) file for full details.

---

## Author & Bug Reports

Written by Timo Savinen.  
Send bug reports, feedback, and patches to <tjsa@iki.fi>.

#!/bin/sh
set -e

BBE="${top_builddir:-.}/src/bbe"
TMPDIR="$(mktemp -d /tmp/bbe_test.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "=== Test 1: Binary search and replace ==="
printf '\x00\x01\x02\xff\xfe\xaaDATABASE_URL=mysql://localhost:3306/olddb\x00\xbb\xcc\xdd' > "$TMPDIR/input.bin"
"$BBE" -e 's#localhost:3306/olddb#production:3306/newdb#' "$TMPDIR/input.bin" > "$TMPDIR/output.bin"
# Verify replacement occurred
grep -q "production:3306/newdb" "$TMPDIR/output.bin"
# Verify binary prefix and suffix preserved
python3 -c '
data = open("'"$TMPDIR"'/output.bin", "rb").read()
assert data.startswith(b"\x00\x01\x02\xff\xfe\xaa")
assert data.endswith(b"\x00\xbb\xcc\xdd")
assert b"production:3306/newdb" in data
'
echo "PASS: Binary search and replace verified"

echo "=== Test 2: ASN.1 DER Certificate Tag Data Replacement ==="
CERT_DER="$TMPDIR/cert.der"
if [ -f /etc/pki/tls/certs/ca-bundle.crt ]; then
    openssl x509 -in /etc/pki/tls/certs/ca-bundle.crt -outform DER -out "$CERT_DER" 2>/dev/null
else
    # Fallback to generating a test cert if system ca-bundle is absent
    openssl req -x509 -newkey rsa:1024 -keyout /dev/null -nodes -subj "/C=ES/O=TestOrg/CN=TestCA" -days 1 -outform DER -out "$CERT_DER" 2>/dev/null
fi

# Replace countryName PrintableString (OID 2.5.4.6 -> \x06\x03\x55\x04\x06, Tag \x13, Len \x02, Val ES -> FI)
"$BBE" -b "/\x06\x03\x55\x04\x06\x13\x02/:9" -e "r 7 FI" "$CERT_DER" > "$TMPDIR/cert_modified.der"

# Verify ASN.1 structure remains valid
openssl asn1parse -inform DER -in "$TMPDIR/cert_modified.der" > "$TMPDIR/asn1.txt"
grep -q "PRINTABLESTRING   :FI" "$TMPDIR/asn1.txt"
openssl x509 -in "$TMPDIR/cert_modified.der" -inform DER -text -noout | grep -q "C=FI"
echo "PASS: ASN.1 tag replacement verified with valid X.509 DER structure"

echo "=== Test 3: Print HEX Dump ==="
printf '\x10\x20\x30\x40\xaa\xbb\xcc\xdd\x01\x02\x03\x04\xee\xff\x11\x22Extra' > "$TMPDIR/hexdump_input.bin"
HEXDUMP_OUT="$("$BBE" -b :16 -s -e "F h;p H;A \n" "$TMPDIR/hexdump_input.bin")"
echo "$HEXDUMP_OUT" | grep -q "x0:x10 x20 x30 x40 xaa xbb xcc xdd x01 x02 x03 x04 xee xff x11 x22"
echo "$HEXDUMP_OUT" | grep -q "x10:x45 x78 x74 x72 x61"

# Joint HEX and ASCII formatting (p HA)
HEXASCII_OUT="$("$BBE" -b :16 -s -e "F h;p HA;A \n" "$TMPDIR/hexdump_input.bin")"
echo "$HEXASCII_OUT" | grep -q "x10:x45-E x78-x x74-t x72-r x61-a"
echo "PASS: HEX and HEX+ASCII dump formatting verified"

echo "ALL TESTS PASSED!"

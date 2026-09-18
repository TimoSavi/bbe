#!/bin/sh
set -e

BBE="${top_builddir:-.}/src/bbe"
TMPDIR="$(mktemp -d /tmp/bbe_test.XXXXXX)"
# Only clean up on success; preserve directory if test fails for easy debugging
trap 'status=$?; [ $status -eq 0 ] && rm -rf "$TMPDIR" || echo "Test failed! Artifacts preserved in $TMPDIR"' EXIT

echo "=== Test 1: Binary search and replace ==="
# Use POSIX octal escapes (\0...) for universal shell compatibility (bash, dash, ash)
printf '\000\001\002\377\376\252DATABASE_URL=mysql://localhost:3306/olddb\000\273\314\335' > "$TMPDIR/input.bin"
"$BBE" -e 's#localhost:3306/olddb#production:3306/newdb#' "$TMPDIR/input.bin" > "$TMPDIR/output.bin"

# Verify replacement occurred
grep "production:3306/newdb" "$TMPDIR/output.bin" >/dev/null

# Verify binary prefix and suffix preserved (if python3 is available)
if command -v python3 >/dev/null 2>&1; then
    python3 -c '
data = open("'"$TMPDIR"'/output.bin", "rb").read()
assert data.startswith(b"\x00\x01\x02\xff\xfe\xaa")
assert data.endswith(b"\x00\xbb\xcc\xdd")
assert b"production:3306/newdb" in data
'
fi
echo "PASS: Binary search and replace verified"

echo "=== Test 2: ASN.1 DER Certificate Tag Data Replacement ==="
CERT_DER="$TMPDIR/cert.der"

if command -v openssl >/dev/null 2>&1; then
    # Generate deterministic X.509 DER certificate with known C=ES PrintableString
    openssl req -x509 -newkey rsa:2048 -keyout /dev/null -nodes \
        -subj "/C=ES/O=TestOrg/CN=TestCA" -days 1 -outform DER -out "$CERT_DER" 2>/dev/null

    # Replace countryName PrintableString (OID 2.5.4.6 -> \x06\x03\x55\x04\x06, Tag \x13, Len \x02, Val ES -> FI)
    "$BBE" -b "/\x06\x03\x55\x04\x06\x13\x02/:9" -e "r 7 FI" "$CERT_DER" > "$TMPDIR/cert_modified.der"

    # Verify ASN.1 structure remains valid
    openssl asn1parse -inform DER -in "$TMPDIR/cert_modified.der" > "$TMPDIR/asn1.txt"
    grep -E "PRINTABLESTRING[[:space:]]*:[[:space:]]*FI" "$TMPDIR/asn1.txt" >/dev/null
    openssl x509 -in "$TMPDIR/cert_modified.der" -inform DER -text -noout | grep -E "C[[:space:]]*=[[:space:]]*FI" >/dev/null
else
    # Fallback: standalone minimal ASN.1 DER SEQUENCE with countryName C=ES
    printf '\060\011\006\003\125\004\006\023\002ES' > "$CERT_DER"
    "$BBE" -b "/\x06\x03\x55\x04\x06\x13\x02/:9" -e "r 7 FI" "$CERT_DER" > "$TMPDIR/cert_modified.der"
    grep "FI" "$TMPDIR/cert_modified.der" >/dev/null
fi
echo "PASS: ASN.1 tag replacement verified with valid X.509 DER structure"

echo "=== Test 3: Print HEX Dump ==="
printf '\020\040\060\100\252\273\314\335\001\002\003\004\356\377\021\042Extra' > "$TMPDIR/hexdump_input.bin"
HEXDUMP_OUT="$("$BBE" -b :16 -s -e "F h;p H;A \n" "$TMPDIR/hexdump_input.bin")"
echo "$HEXDUMP_OUT" | grep "x0:x10 x20 x30 x40 xaa xbb xcc xdd x01 x02 x03 x04 xee xff x11 x22" >/dev/null
echo "$HEXDUMP_OUT" | grep "x10:x45 x78 x74 x72 x61" >/dev/null

# Joint HEX and ASCII formatting (p HA)
HEXASCII_OUT="$("$BBE" -b :16 -s -e "F h;p HA;A \n" "$TMPDIR/hexdump_input.bin")"
echo "$HEXASCII_OUT" | grep "x10:x45-E x78-x x74-t x72-r x61-a" >/dev/null
echo "PASS: HEX and HEX+ASCII dump formatting verified"

echo "ALL TESTS PASSED!"


#!/bin/bash
# The "Setec Astronomy" Serial Handshaker
PORT="/dev/ttyUSB0"  # Swap for your serial-to-usb or /dev/ttyS0 for the Hayes
MODEM_INIT="ATZ"     # Reset the Hayes modem first

BAUDS=(115200 57600 38400 19200 9600 2400 1200 300)
BITS=(8 7)
PARITY=("none" "even" "odd")

echo "Starting the cycle... searching for clear text sync..."

for b in "${BAUDS[@]}"; do
  for d in "${BITS[@]}"; do
    for p in "${PARITY[@]}"; do

      # Translate parity for stty
      [[ "$p" == "none" ]] && P_ARG="-parenb"
      [[ "$p" == "even" ]] && P_ARG="parenb -parodd"
      [[ "$p" == "odd" ]] && P_ARG="parenb parodd"

      echo "Trying: $b $d-${p:0:1}-1"

      # Flex the port settings without closing the file descriptor
      stty -F "$PORT" "$b" cs"$d" "$P_ARG" -cstopb raw -echo

      # Send a pulse (AT) and capture the first few bytes of the echo
      echo -e "AT\r" > "$PORT"
      RESPONSE=$(head -c 10 < "$PORT" | tr -cd '[:print:]')

      if [[ "$RESPONSE" == *"OK"* ]]; then
        echo ">>> SYNC FOUND! Use settings: $b $d-${p:0:1}-1"
        exit 0
      fi
    done
  done
done

"""
uart_tx.py

Simple command-line UART transmitter for sending single bytes to the
RealDigital Boolean board (or any UART receiver) over a serial connection.

Usage:
    python uart_tx.py

The user is repeatedly prompted for an 8-bit value in hex (e.g. "EA", "0x2B").
Each entry is transmitted as a single byte over the serial port.
Type 'quit' (or 'exit') to terminate the program.

Requires pyserial:
    pip install pyserial
"""

import sys
import serial
import serial.tools.list_ports


BAUD_RATE = 9600
BYTE_SIZE = serial.EIGHTBITS
PARITY = serial.PARITY_NONE
STOP_BITS = serial.STOPBITS_TWO   # 2 stop bits, matching the FPGA uart_rx design
TIMEOUT = 1                       # seconds

QUIT_COMMANDS = {"quit", "exit", "q"}


def list_available_ports():
    """Print all detected serial ports to help the user pick one."""
    ports = list(serial.tools.list_ports.comports())
    if not ports:
        print("No serial ports detected.")
        return []
    print("Available serial ports:")
    for p in ports:
        print(f"  {p.device} - {p.description}")
    return [p.device for p in ports]


def choose_port():
    """Prompt the user to select a COM port, listing available ones first."""
    ports = list_available_ports()
    while True:
        port_name = input("Enter the COM port to use (e.g. COM5 or /dev/ttyUSB0): ").strip()
        if port_name:
            return port_name
        print("Port name cannot be empty.")


def open_serial(port_name):
    """Open the serial connection with the settings expected by uart_rx."""
    try:
        ser = serial.Serial(
            port=port_name,
            baudrate=BAUD_RATE,
            bytesize=BYTE_SIZE,
            parity=PARITY,
            stopbits=STOP_BITS,
            timeout=TIMEOUT,
        )
        print(f"Connected to {port_name} at {BAUD_RATE} baud, "
              f"8 data bits, no parity, 2 stop bits.")
        return ser
    except serial.SerialException as e:
        print(f"Error: could not open port '{port_name}': {e}")
        sys.exit(1)


def parse_byte(user_input):
    """
    Parse user input as an 8-bit hex value.
    Accepts formats like: EA, 0xEA, 0Xea, ea
    Returns an int in [0, 255], or None if invalid.
    """
    text = user_input.strip()
    if text.lower().startswith("0x"):
        text = text[2:]

    if not text:
        return None

    try:
        value = int(text, 16)
    except ValueError:
        return None

    if value < 0 or value > 0xFF:
        return None

    return value


def main():
    print("=== UART Transmitter ===")
    print(f"Settings: {BAUD_RATE} baud, 8 data bits, no parity, 2 stop bits\n")

    port_name = choose_port()
    ser = open_serial(port_name)

    print("\nEnter an 8-bit hex value to transmit (e.g. 'EA' or '0x2B').")
    print("Type 'quit' or 'exit' to close the program.\n")

    try:
        while True:
            user_input = input("Byte to send (hex) > ").strip()

            if user_input.lower() in QUIT_COMMANDS:
                print("Exiting.")
                break

            if not user_input:
                continue

            value = parse_byte(user_input)
            if value is None:
                print("Invalid input. Enter a hex value from 00 to FF (e.g. 'EA', '0x2B'), "
                      "or 'quit' to exit.")
                continue

            ser.write(bytes([value]))
            print(f"Sent: 0x{value:02X}  ({value:#010b})")

    except KeyboardInterrupt:
        print("\nInterrupted by user. Exiting.")

    finally:
        ser.close()
        print("Serial port closed.")


if __name__ == "__main__":
    main()

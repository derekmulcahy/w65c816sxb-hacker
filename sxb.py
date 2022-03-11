#!/usr/bin/env python3
# https://github.com/kalj/sxb

import argparse
import serial
import pathlib
import sys
import time
import os

SBC_DEVICE = os.environ.get("SBC_DEVICE") if "SBC_DEVICE" in os.environ else "/dev/ttyUSB0"

STATE_ADDRESS = 0x7e00

CMD_SYNC        = 0x0
CMD_ECHO        = 0x1
CMD_WRITE_MEM   = 0x2
CMD_READ_MEM    = 0x3
CMD_GET_INFO    = 0x4
CMD_EXEC_DEBUG  = 0x5
# CMD_EXEC_MEM    = 0x6
# CMD_WRITE_FLASH = 0x7
# CMD_READ_FLASH  = 0x8
# CMD_CLEAR_FLASH = 0x9
# CMD_CHECK_FLASH = 0xa
# CMD_EXEC_FLASH  = 0xb

def lo(x):
    return x & 0xff

def hi(x):
    return (x >> 8) & 0xff

def bank(x):
    return (x >> 16) & 0xff

def initiate_command(ser, cmd):
    ser.write(bytes([0x55, 0xaa]))
    resp = ser.read(1)

    if len(resp) != 1 or resp[0] != 0xcc:
        raise RuntimeError("No response from SXB -- Try pressing RESET");

    ser.write(bytes([cmd]))

def write_memory(ser, addr, data):
    initiate_command(ser, CMD_WRITE_MEM)

    data_len = len(data)
    ser.write(bytes([lo(addr), hi(addr), bank(addr), lo(data_len), hi(data_len)]))

    for b in data:
        ser.write(bytes([b]))
        time.sleep(0.000_001)       # Wait just a microsecond.

def read_memory(ser, addr, data_len):
    initiate_command(ser, CMD_READ_MEM)

    ser.write(bytes([lo(addr), hi(addr), bank(addr), lo(data_len), hi(data_len)]))

    data = ser.read(data_len)
    return data

def exec_command(ser, addr):
        state = [ 0x00, 0x00, # A
                  0x00, 0x00, # X
                  0x00, 0x00, # Y

                  lo(addr), hi(addr), # PC

                  0,              # 8
                  0,              # 9
                  0xff,           # A stack pointer
                  1,              # B
                  0,              # C processor status bits
                  1,              # D CPU mode (0=65816, 1=6502)
                  0,              # E
                  0]              # F

        write_memory(ser, STATE_ADDRESS, bytes(state))
        initiate_command(ser, CMD_EXEC_DEBUG)

def wdc_write(ser, data):
    from struct import unpack

    if chr(data[0]) != 'Z':
        sys.exit(f"WDC Binary files start with 'Z', this file does not!")

    offset = 1
    while True:
        (addr,addrb,size,sizeb) = unpack('<HBHB', data[offset:offset+6])
        if size == 0:
            break
        addr += addrb << 16
        size += sizeb << 16
        offset += 6
        write_memory(ser, addr, data[offset:offset+size])
        offset += size

def format_table(data,offset=0):
    BYTES_PER_LINE=16

    output=[]
    header=" addr |"+"".join([f" {i:2d}" for i in range(BYTES_PER_LINE)])
    output.append(header)
    output.append(' '+'-'*(len(header)-1))

    lineoffset=offset % BYTES_PER_LINE
    base=offset-lineoffset
    n_bytes_left = len(data)
    dataptr=0

    while n_bytes_left > 0:
        chunk_size = min(n_bytes_left,BYTES_PER_LINE-lineoffset)
        chunk = data[dataptr:(dataptr+chunk_size)]
        elems=lineoffset*["   "]+[f" {b:02x}" for b in chunk]
        output.append(f" {base:04x} |" + "".join(elems))

        base += BYTES_PER_LINE
        dataptr += chunk_size
        n_bytes_left -= chunk_size
        lineoffset = 0 # only first time is relevant

    return output


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('-d', '--device', help='Serial device', default=SBC_DEVICE)

    subparsers = parser.add_subparsers(dest='command',required=True,metavar='command')

    info_p = subparsers.add_parser("info", help="Get board info")

    getstate_p = subparsers.add_parser("getstate", help="Get state")

    read_p = subparsers.add_parser("read", help="Read bytes")
    read_p.add_argument('-t', '--table', action='store_true')
    read_p.add_argument("addr")
    read_p.add_argument("size")

    write_p = subparsers.add_parser("write", help="Write bytes")
    write_p.add_argument("addr")
    write_p.add_argument("file")

    write_p = subparsers.add_parser("wdc", help="Write WDC file")
    write_p.add_argument("-e", "--exec")
    write_p.add_argument("file")

    cont_p = subparsers.add_parser("cont", help="Continue execution")
    # cont_p.add_argument("-t", "--terminal", help="Start terminal after finish", action='store_true')

    exec_p = subparsers.add_parser("exec", help="Start execution")
    # exec_p.add_argument("-t", "--terminal", help="Start terminal after finish", action='store_true')
    exec_p.add_argument("addr")

    echo_p = subparsers.add_parser("echo", help="Echo ?")
    echo_p.add_argument("count", type=int)

    args = parser.parse_args()

    dev = args.device

    ser = serial.Serial(port=dev,
                        baudrate=57600,
                        parity=serial.PARITY_NONE,
                        stopbits=serial.STOPBITS_ONE,
                        bytesize=serial.EIGHTBITS )

    if args.command == "info":
        initiate_command(ser, CMD_GET_INFO)

        info = ser.read(29)
        for i,l in enumerate(info):
            print(f'{i:02x}  {l:02x}  {l:c}')

    elif args.command == 'read':
        addr = int(args.addr,0)
        size = int(args.size,0)

        data = read_memory(ser, addr, size)

        if args.table:
            lines = format_table(data, addr)
            for l in lines:
                print(l)
        else:
            sys.stdout.buffer.write(data)

    elif args.command == "wdc":
        data = pathlib.Path(args.file).read_bytes()
        wdc_write(ser, data)
        if args.exec:
            exec_command(ser, int(args.exec,0))

    elif args.command == 'write':
        addr = int(args.addr,0)

        data = pathlib.Path(args.file).read_bytes()
        write_memory(ser, addr, data)

    elif args.command == 'getstate':

        state = read_memory(ser, STATE_ADDRESS, 16)
        a  = state[0x0] + (state[0x1]<<8)
        x  = state[0x2] + (state[0x3]<<8)
        y  = state[0x4] + (state[0x5]<<8)
        pc = state[0x6] + (state[0x7]<<8)
        dp = state[0x8] + (state[0x9]<<8)
        sp = state[0xa] + (state[0xb]<<8)
        procstat = state[0xc]
        cpumode  = state[0xd]
        pb = state[0xe] # Program Bank, aka K register
        db = state[0xf] # Data Bank, aka D register


        print(f"A:  ${a:04x}")
        print(f"X:  ${x:04x}")
        print(f"Y:  ${y:04x}")
        print(f"PC: ${pc:04x}")
        print(f"DP: ${dp:04x}")
        print(f"SP: ${sp:04x}")
        print(f"PS: ${procstat:02x}")
        print(f"CM: ${cpumode:02x}")
        print(f"PB: ${pb:02x}")
        print(f"DB: ${db:02x}")

    elif args.command == 'exec':

        # initiate_command(ser, CMD_EXEC_MEM)

        # addr = int(args.addr,0)
        # ser.write(bytes([addr & 0xff, (addr >> 8) & 0xff, 0]))

        addr = int(args.addr,0)

        exec_command(ser, addr)

    elif args.command == 'cont':
        initiate_command(ser, CMD_EXEC_DEBUG)

    elif args.command == 'echo':

        initiate_command(ser, CMD_ECHO)

        count = args.count
        ser.write(bytes([lo(count), hi(count)]))

        for i in range(count):
            print(f'sent:     {i}')
            ser.write(bytes([i]))
            response = ser.read(1)[0]
            print(f"received: {response}")

    else:
        raise RuntimeError(f'Invalid command received: {args.command}')
# RISC-V Zephyr Docker

Build Zephyr firmware proejcts and flash (specifically RISC-V) targets from a Docker container! 

Intended for development tests without mangling the local machine, and allows CI build and flash sequences.

___

***Why?***

Compared to other publicly available Zephyr docker images, *this* container's benefits are (at time of writing) age and specificity:

- Tested against the [Sparkfun RED-V Thing Plus](https://www.sparkfun.com/products/15799) (`FE310-G002`), and [used in production](https://electricui.com/blog/hardware-testing).
  - Environment setup is similar to the [Sparkfun RED-V development guide](https://learn.sparkfun.com/tutorials/red-v-development-guide) with some bug fixes and QoL improvements.
- Includes the latest SEGGER J-Link tools needed to interface with the [RED-V's onboard J-Link programmer](https://wiki.segger.com/J-Link-OB-K22-SiFive).
- Exists outside of the official Zephyr docker images, which means it doesn't bundle extra weight for building/testing Zephyr itself, or unnecessary compilers etc.

- No hardcoded version/dependencies - uses some bash tricks to ensure we use the latest (stable) Zephyr SDK and J-Link tools when building the docker container.

# Usage

Build the docker image from the Dockerfile: `docker build --tag riscv-zephyr:0.4 .`

Use the toolchain interactively: `docker run -i --privileged --rm -v $PWD:/project -w /project riscv-zephyr:0.4`

> We use `-i --privileged` to allow the container access over all USB devices. This is considered a insecure in general use, so consider only [providing the required hardware](https://stackoverflow.com/questions/24225647/docker-a-way-to-give-access-to-a-host-usb-or-serial-device).
>
> The onboard J-Link programmer on the RED-V is listed by `lsusb` as `1366:1061 SEGGER HiFive`, and presents as a pair of `/dev/ttyACMx` entries (UART passthrough, and the JTAG programmer respectively).

## Build/Flash/Run Example

This is provided as reference for a working build/flash output. Run the following while using the docker container interactively as described above:

1. `west init testproject`

2. `cd testproject`

3. `west update`

4. `pip3 install -r zephyr/scripts/requirements.txt`

5. `west build -b hifive1_revb samples/hello_world`

6. `west flash`

   ```
   -- west flash: rebuilding
   [0/1] cd /project/hello-electricui/zephyr/build/zephyr/cmake/flash && /usr/bin/cmake -E echo
   
   -- west flash: using runner jlink
   -- runners.jlink: Flashing file: /project/hello-electricui/zephyr/build/zephyr/zephyr.bin
   SEGGER J-Link Commander V6.82c (Compiled Jul 31 2020 17:40:13)
   DLL version V6.82c, compiled Jul 31 2020 17:40:02
   
   J-Link Command File read successfully.
   Processing script file...
   
   J-Link connection not established yet but required for command.
   Connecting to J-Link via USB...O.K.
   Firmware: J-Link OB-K22-SiFive compiled Jun 17 2020 14:52:05
   Hardware version: V1.00
   S/N: 979004978
   VTref=3.300V
   Target connection not established yet but required for command.
   Device "FE310" selected.
   
   Connecting to target via JTAG
   ConfigTargetSettings() start
   ConfigTargetSettings() end
   TotalIRLen = 5, IRPrint = 0x01
   JTAG chain detection found 1 devices:
    #0 Id: 0x20000913, IRLen: 05, Unknown device
   Debug architecture:
     RISC-V debug: 0.13
     AddrBits: 7
     DataBits: 32
     IdleClks: 5
   Memory access:
     Via system bus: No
     Via ProgBuf: Yes (16 ProgBuf entries)
   DataBuf: 1 entries
     autoexec[0] implemented: Yes
   Detected: RV32 core
   CSR access via abs. commands: No
   Temp. halted CPU for NumHWBP detection
   HW instruction/data BPs: 8
   Support set/clr BPs while running: No
   HW data BPs trigger before execution of inst
   RISC-V identified.
   Reset delay: 0 ms
   Reset type Normal: Resets core & peripherals using <ndmreset> bit in <dmcontrol> debug register.
   RISC-V: Performing reset via <ndmreset>
   
   Downloading file [/project/hello-electricui/zephyr/build/zephyr/zephyr.bin]...
   /opt/SEGGER/JLink_V682c/JLinkGUIServerExe: error while loading shared libraries: libSM.so.6: cannot open shared object file: No such file or directory
   J-Link: Flash download: Bank 0 @ 0x20000000: 1 range affected (65536 bytes)
   J-Link: Flash download: Total: 1.183s (Prepare: 0.384s, Compare: 0.320s, Erase: 0.137s, Program & Verify: 0.328s, Restore: 0.013s)
   J-Link: Flash download: Program & Verify speed: 194 KB/s
   O.K.
   
   Writing DP register 1 = 0x00000000 (0 write repetitions needed)
   Reading DP register 1 = 0x00000001 (0 read repetitions needed)
   
   Script processing completed.
   ```

7. Connect to the programmer's passthrough serial port (`/dev/ttyACM0` for me) with a serial terminal at `115200 baud` and the board should output the following at boot:

   ```
   ATE0-->Send Flag Timed Out Busy. Giving Up.
    Send Flag error: #0 #0 #0 #0 AT+BLEINIT=0-->Send Flag Timed Out Busy. Giving Up.
    Send Flag error: #0 #0 #0 #0 AT+CWMODE=0-->Send Flag Timed Out Busy. Giving Up.
    Send Flag error: #0 #0 #0 #0 
   *** Booting Zephyr OS build zephyr-v2.3.0-1733-g9df168b53569  ***
   Hello World! hifive1_revb
   ```

That's it!

# Troubleshooting

## J-Link does not support selecting another hart/core

At time of writing (Aug 2020) the Sparkfun RED-V Thing Plus didn't work out of the box with recent Segger JLink tooling (validated against two separate boards).

When running `west flash` to burn a firmware file, errors like this are output:

```
Connecting to J-Link via USB...JLinkGUIServerExe: cannot connect to X server 
O.K.
Firmware: J-Link OB-K22-SiFive compiled Feb 28 2019 12:46:23
Hardware version: V1.00
S/N: 979004978
VTref=3.300V
Target connection not established yet but required for command.
Device "FE310" selected.

[... removed JTAG Chain detection output which successfully detects the RV32 core etcc ...]

****** Error: The connected J-Link does not support selecting another hart/core than 0 for RISC-V
Specific core setup failed.
Cannot connect to target.

Target connection not established yet but required for command.
Device "FE310" selected.

```

The solution is to **update the devkit's onboard J-Link programmer firmware**.

I didn't do this through the docker container, as CLI based update instructions aren't easy to find.

> I've used J-Link V6.82c as it was the most up to date, but reading suggests anything >V6.50 should resolve these issues...

1. On my native workstation, with J-Link V6.82c running, run `JLinkConfigExe`.
2. The GUI will launch, showing Segger programmer images, some empty lists/boxes and simple buttons. 
   - Look for hardware in the "Connected via USB" area.
3. Unplug and replug USB if it wasn't found, mine wasn't found immediately. You should see `J-Link OB-K22-SiFive [...]` in the list.
   - My board showed an older probe version dated `2019 Feb`.

4. Select the listed unit, then click `Update firmware of selected probes and programmers`.
5. Wait for the update to complete. Once done, the probe firmware was listed as built on `2020 June 17 14:52`.
6. Close the tool. Plug/unplug the board to properly power cycle everything.
7. Reattempt flashing the target with `west flash` inside the Docker container.

## J-Link Failed to open DLL

After resolving the J-Link firmware version issues, this might appear:

```
J-Link connection not established yet but required for command.
Connecting to J-Link via USB...FAILED: Failed to open DLL
```

In my case, this worked after I had ensured Zephyr was up to date and properly installed. From a project (`west init testproject` then `cd testproject`), ensure the python requirements have actually been installed!

```
west update
sudo pip3 install -r zephyr/scripts/requirements.txt
```


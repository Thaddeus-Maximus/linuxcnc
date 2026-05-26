
This is how I have my LinuxCNC machine wired. I put a linuxCNC box in place of a Southwestern Industries TRAK CNC II control box. I am reusing the TRAK drives, motors, and encoders. Eventually, I switched to using linear encoders instead of the TRAK encoders.

| Mesa card | Role                            |
| --------- | ------------------------------- |
| 6i24-16   | FPGA card (PCIe host interface) |
| 7i52S     | Servo interface daughter card   |
| 7i37TA    | Isolated I/O daughter card      |

![[pc_front.jpg]]
![[cbox_back.jpg]]
![[cbox_inside.jpg]]

## TRAK Encoder Pinout

The encoders for both motors and the standard TRAK encoders use the same Amphenol CPC connector.

The encoders are differential 5V output. They might have an index pulse but I wasn't using it. The Z axis has the same pinout.

| Pin | Signal | Color (in PC) |
| --- | ------ | ------------- |
| 1   | B-     | White         |
| 2   | 5V     | Red           |
| 3   | B+     | Blue          |
| 4   | N/C    |               |
| 5   | N/C    |               |
| 6   | N/C    |               |
| 7   | N/C    |               |
| 8   | N/C    |               |
| 9   | GND    | Black         |
| 10  | GND    | Black         |
| 11  | GND    | Black         |
| 12  | A-     | Yellow        |
| 13  | GND    | Black         |
| 14  | A+     | Green         |
![[ampconns.jpg]]
## Linear Encoder Pinout (DB9)

I switched to some linear encoders that have a D-sub connector. They are also 5V differential output, and nearly the same resolution, resulting in very easy switchover.

| Pin | Signal | Color (in PC) |
| --- | ------ | ------------- |
| 1   | A-     | Yellow        |
| 2   | GND    | Black         |
| 3   | B-     | White         |
| 4   | N/C    | N/C           |
| 5   | Z-     | Tan           |
| 6   | A+     | Green         |
| 7   | 5V     | Red           |
| 8   | B+     | Blue          |
| 9   | Z+     | Maroon        |


## DB37 Pinout

The DB37 cable contains drive signals and motor encoder signals.

*This pinout was determined by probing. I'm not sure what some of the pins do; some of the pins labelled GND or 5V might actually be an index pulse or something.*


| Pin   | Signal     | Notes     |
| ----- | ---------- | --------- |
| 1-5   | ??? (N/C?) |           |
| 6     | YB-        | Y Encoder |
| 7     | YB+        | Y Encoder |
| 8     | YA+        | Y Encoder |
| 9     | YA-        | Y Encoder |
| 10    | XB+        | X Encoder |
| 11    | XB-        | X Encoder |
| 12    | XA+        | X Encoder |
| 13    | XA-        | X Encoder |
| 14    | XENW       | X Enable  |
| 15    | XENR       | X Enable  |
| 16    | YENW       | Y Enable  |
| 17    | YENR       | Y Enable  |
| 18    | ZENW       | Z Enable  |
| 19    | ZENR       | Z Enable  |
| 20    | ??? (N/C?) |           |
| 21    | 5V         |           |
| 22    | 5V         |           |
| 23    | GND        |           |
| 24    | GND        |           |
| 25    | 5V         |           |
| 26    | 5V         |           |
| 27    | GND        |           |
| 28    | GND        |           |
| 29    | 5V         |           |
| 30    | 5V         |           |
| 31-37 | GND        |           |

# MESA Cards

![[mesa_cards.jpg]]
## 7i37TA

Three enables are used - one for the X and Y axes, one for the z axis, and one for the spindle. This allows the z axis to be disabled independently for manual drilling operations.

Each works by connecting a pair of wires. Made = enabled.

The spindle only has enable; direction and speed is manually controlled.

A custom `M101` and `M102` g code enables/disables the z-axis.

| Enable  | 7i37TA Pin | 6i24-16 Pin | Wire Color             |
| ------- | ---------- | ----------- | ---------------------- |
| XY      | OUT6+      | 46          | White & Green to black |
| Z       | OUT4+      | 44          | Red to black           |
| Spindle | OUT3+      | 41          | White to Green         |

## 7i52S

#### Encoder connector
(This is for connector 0; carries over to channels 0-4 as well)

*Five encoder inputs are used - x, y, and z each use one without index pulse, and x and y have a secondary linear encoder that does use the index pulse*

*Sometimes the A-channels and B-channels are flipped, at least color-wise.*

| Pin | Signal | Function | Wire Color |
| --- | ------ | -------- | ---------- | 
| 1   | QA0    | A+       | Green      |
| 2   | /QA0   | A-       | Yellow     |
| 3   | GND    | GND      | Black      |
| 4   | QB0    | B+       | Blue       |
| 5   | /QB0   | B-       | White      |
| 6   | +5V    | 5V       | Red        |
| 7   | IDX0   | I+       | Maroon     |
| 8   | /IDX0  | I-       | Tan        |

#### Differential Output Connector

*Three differential outputs are used - one for each x, y, and z*

| Pin | Signal | Function | Color |
| --- | ------ | -------- | ----- |
| 1   | GND    |          | N/C   |
| 2   | GND    |          | N/C   |
| 3   | TX0A   | TXA+     | White |
| 4   | /TX0A  | TXA-     | Green |
| 5   | TX0B   |          | N/C   |
| 6   | /TX0B  |          | N/C   |
| 7   | +5V    |          | N/C   |
| 8   | +5V    |          | N/C   |

#### HAL Channel assignments

| Axis     | Encoder ch   | PWM ch      | Notes                     |
| -------- | ------------ | ----------- | ------------------------- |
| X linear | `encoder.00` | —           | Joint position feedback   |
| Y linear | `encoder.01` | —           | Joint position feedback   |
| Z linear | `encoder.02` | —           | Joint position feedback   |
| X motor  | `encoder.03` | —           | Velocity/damping feedback |
| Y motor  | `encoder.04` | —           | Velocity/damping feedback |
| Z motor  | (none)       | —           | No dual loop on Z         |
| X drive  | —            | `pwmgen.00` | Differential PWM out      |
| Y drive  | —            | `pwmgen.02` | Differential PWM out      |
| Z drive  | —            | `pwmgen.04` | Differential PWM out      |

## Servo Drive Config

### PWM

- Carrier: **15.5 kHz** (`hm2_5i24.0.pwmgen.pwm_frequency 15500`)
- `output-type 1` (PWM + Direction pins)
- `offset-mode 1` → locked anti-phase / bipolar single-signal: duty cycle directly encodes signed command
- `scale = OUTPUT_SCALE`: X = +1, Y = -1, Z = -1 (sign flips drive polarity to match wiring)
- Duty cycle = `(value/scale + 1) / 2`

| Commanded value | Duty cycle | Meaning      |
| --------------- | ---------- | ------------ |
| -1.0            | 0 %        | full reverse |
| -0.5            | 25 %       | half reverse |
| 0.0             | **50 %**   | stop         |
| +0.5            | 75 %       | half forward |
| +1.0            | 100 %      | full forward |

When the enable line is deasserted the pwmgen output is forced off (not 50%), so the amp sees a distinct disabled state vs. "commanded zero".

### Enable

Enable lines are switched by 7i37TA isolated MOSFET outputs (`OBITn+`/`OBITn-`). Per the 7i37 manual, a **low** FPGA pin turns the MOSFET **on**. HAL sets `invert_output true` on the enable GPIOs, so HAL `enable=TRUE` → FPGA-low → MOSFET on → contact **closed**.

| HAL enable | FPGA pin | MOSFET | Contact | Drive    |
| ---------- | -------- | ------ | ------- | -------- |
| TRUE       | LOW      | ON     | made    | enabled  |
| FALSE      | HIGH     | OFF    | broken  | disabled |

Fail-safe: cable cut, 5 V loss, or hm2 unconfigured all leave the MOSFET off → contact open → drive disabled.

![[cbox_bottom.jpg]]
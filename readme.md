---
---

# Bob

Lowpass filter with LFO/envelope follower modulation

## Operation

![screenshot](screen/bob.png)

- `ENC1` adjusts main output level.
- `ENC2` changes first parameter displayed on screen.
- `ENC3` changes second parameter displayed on screen.
- `KEY2` go to previous page.
- `KEY3` go to next page.
- `KEY2`+`KEY3` fine tune parameter mode.
- `ARC` first two encoders act as norns `ENC2` and `ENC3`.

## Parameters

- `CUTOFF` / `Cutoff` - `20Hz`...`10kHz`. Filter cutoff frequency.
- `RES` / `Resonance` - `0`...`100%`. Filter resonance.
- `LFO` / `LFO Rate` - `0.01Hz`..`50Hz`.
- `L>FRQ` / `LFO > Cutoff` - `-100%`..`+100%`. Filter cutoff LFO modulation amount.
- `E.ATK` / `EnvF Attack` - `0.1ms`...`2s`. Envelope follower attack time.
- `E.DEC` / `EnvF Decay` - `0.1ms`...`8s`. Envelope follower release time.
- `E.SNS` / `EnvF Sensitivity` - `0.1ms`...`8s`. Envelope follower sensitivity.
- `E>FRQ` / `EnvF > Cutoff` - `-100%`...`+100%`. Envelope follower cutoff modulation amount.

Parameters are available both in script mode (short names) and in the global parameters list.

---
---

# Moln

Polyphonic subtractive synthesizer

## Features

- 2 square oscillators per voice with variable pulse width and pulse width modulation.
- Resonant lowpass filter
- ADSR envelope

## Operation

![screenshot](screen/moln-2.png)

- `ENC1` adjusts main output level.
- `ENC2` changes first parameter displayed on screen.
- `ENC3` changes second parameter displayed on screen.
- `KEY2` go to previous page.
- `KEY3` go to next page.
- `KEY2`+`KEY3` fine tune parameter mode.
- `ARC` first two encoders act as norns `ENC2` and `ENC3`.
- `MIDI` device plays notes.
- `GRID` plays notes too.

## Parameters

- `FREQ` / `Filter Frequency` - `10Hz`...`8kHz`. Lowpass filter cutoff frequency.
- `RES` / `Filter Resonance` - `0`...`100%`. Lowpass filter cutoff resonance.
- `A.RNG` / `Osc A Range` - `-2`..`+2`. Octave range.
- `B.RNG` / `Osc B Range` - `-2`..`+2`. Octave range.
- `A.PW` / `Osc A Pulse Width` - `0`..`100%`.
- `B.PW` / `Osc B Pulse Width` - `0`..`100%`.
- `DETUN` / `Osc Detune` - `0`...`100%`. Detunes the two oscillators.
- `LFO` / `PWM Rate` - `0.01Hz`..`50Hz`. Pulse Width Modulation rate.
- `PWM` / `PWM Depth` - `0`...`100%`. Pulse Width Modulation depth.
- `E>FIL` / `Env > Filter Frequency` - `-100%`...`100%`. Lowpass filter envelope modulation amount.
- `E.ATK` / `Env Attack` - `0.1ms`...`2s`. ADSR envelope attack time.
- `E.DEC` / `Env Decay` - `0.1ms`...`8s`. ADSR envelope decay time.
- `E.SUS` / `Env Sustain` - `0`...`100%`. ADSR envelope sustain level.
- `E.REL` / `Env Release` - `0.1ms`...`8s`. ADSR envelope release time.

Parameters are available both in script mode (short names) and in the global parameters list.

---
---

# Rymd

Cross-feedback delay with damping and delay line modulation

## Operation

![screenshot](screen/rymd.png)

- `ENC1` adjusts main output level.
- `ENC2` changes first parameter displayed on screen.
- `ENC3` changes second parameter displayed on screen.
- `KEY2` go to previous page.
- `KEY3` go to next page.
- `KEY2`+`KEY3` fine tune parameter mode.
- `ARC` first two encoders act as norns `ENC2` and `ENC3`.

## Parameters

- `DIR` / `Direct` - `-inf`...`+12dB`. Direct signal level
- `SEND` / `Delay Send` - `-inf`...`+12dB`. Delay send level.
- `L.TIME` / `Delay Time Left` - `0.1ms`..`5s`. Default is 400ms.
- `R.TIME` / `Delay Time Right` - `0.1ms`..`5s`. Default is 400ms.
- `DAMP` / `Damping` - `300Hz`..`10kHz`. Lowpass filter damping in delay feedback path.
- `FBK` / `Feedback` - `0%`...`100%`. Delay feedback.
- `RATE` / `Mod Rate` - `0.01Hz`...`50Hz`. Modulation rate.
- `MOD` / `Delay Time Mod Depth` - `0`...`100%`. Delay time modulation depth.

Parameters are available both in script mode (short names) and in the global parameters list.

---
---

# Skev

Pitch and frequency shifter with modulation

## Operation

![screenshot](screen/skev.png)

- `ENC1` adjusts main output level.
- `ENC2` changes first parameter displayed on screen.
- `ENC3` changes second parameter displayed on screen.
- `KEY2` go to previous page.
- `KEY3` go to next page.
- `KEY2`+`KEY3` fine tune parameter mode.
- `ARC` first two encoders act as norns `ENC2` and `ENC3`.

## Parameters

- `F.SHFT` / `Freq Shift` - `-2000Hz`...`+2000Hz`.
- `P.RAT` / `Pitch Ratio` - `0%`...`400%`.
- `P.DISP` / `Pitch Dispersion` - `0%`...`400%`.
- `T.DISP` / `Time Dispersion` - `0%`...`100%`.
- `LFO.HZ` / `LFO Rate` - `0.01Hz`..`50Hz`.
- `>F.SHFT` / `LFO > Freq Shift` - `-100%`...`+100%`. LFO frequency shift modulation.
- `>P.RAT` / `LFO > Pitch Ratio` - `-100%`...`+100%`. LFO pitch ratio modulation.

Parameters are available both in script mode (short names) and in the global parameters list.


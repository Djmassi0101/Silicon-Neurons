# Silicon-Neurons

## Overview

This project implements a systolic-style TPU tile in Verilog capable of computing an 8×8 matrix multiplied by an 8-element vector in a fully pipelined manner. The design is composed of three hierarchical modules: `mac_unit`, `dot_product_engine`, and `tpu_tile`.

---

## Pipeline Architecture

The core compute unit is the `dot_product_engine`, which computes a dot product between one row of the weight matrix and the input vector. The engine is structured as a 4-stage synchronous pipeline, where every stage is separated by a bank of registers clocked on the rising edge of the system clock.

**Stage 1 — Parallel Multiplication**

Eight MAC units execute simultaneously, each multiplying one element of the matrix row by the corresponding element of the input vector. The inputs are 8-bit unsigned integers, and each product is registered as a 16-bit value. This stage captures all eight partial products in a single clock cycle.

**Stage 2 — First Adder Level (8 → 4)**

The eight 16-bit products are reduced to four 17-bit partial sums through four parallel adders. The extra bit at this stage is necessary to accommodate the carry out of adding two 16-bit values, preventing silent overflow. All four sums are registered at the end of this stage.

**Stage 3 — Second Adder Level (4 → 2)**

The four 17-bit partial sums are further reduced to two 18-bit values. Again, one bit is added to the width to capture any carry. These two intermediate sums are registered before passing to the final stage.

**Stage 4 — Final Accumulation**

The two 18-bit sums are added to produce the final 24-bit dot product result. A 24-bit output is chosen to safely accommodate the worst-case sum of eight products of 255 × 255, which equals 520,200 — well within the 24-bit range of 16,777,215.

---

## Throughput Analysis

Although the pipeline introduces a 4-cycle latency for the first result, steady-state throughput is one dot product per clock cycle. If inputs are applied on consecutive clock cycles, the pipeline is fully occupied and produces one 24-bit result every cycle. At a target clock frequency of 100 MHz on the Zynq Z7 FPGA, this yields a throughput of 100 million dot products per second per engine, and 800 million dot products per second across all 8 engines of the full TPU tile.

---

## TPU Tile Parallelism

The top-level `tpu_tile` module instantiates 8 `dot_product_engine` units using a `generate` loop. Each engine receives a different row of the weight matrix and the same shared input vector. All 8 engines are active simultaneously on every clock cycle. Their outputs are 8 independent 24-bit values, collectively forming the result vector of the matrix-vector multiplication. The `valid_out` signal is taken from engine 0 and is representative of all engines, since they are structurally identical and receive the same `valid_in`.

---

## Bit Width Growth Summary

| Stage | Operation | Output Width |
|---|---|---|
| Input | 8-bit × 8-bit multiply | 16 bits |
| Stage 2 | 16 + 16 | 17 bits |
| Stage 3 | 17 + 17 | 18 bits |
| Stage 4 | 18 + 18 | 19 bits minimum, 24 bits used |

The output is widened to 24 bits to match the requirement specification and to provide margin for future accumulation across multiple inference passes.

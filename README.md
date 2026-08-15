# AI Playground

A personal collection of notes, scripts, and reproducible setup guides for building and experimenting with a local AI system on Debian and NVIDIA hardware.

## Hardware

The documented setup is based on the following workstation configuration:

**Mainboard:** ASUS Pro WS WRX90E-SAGE SE

**CPU:** AMD Ryzen™ Threadripper™ PRO 7975WX

**Memory:** 8 × ADATA 32 GB DDR5-5600 ECC RDIMM, 256 GB total

**GPU:** 2 × NVIDIA RTX PRO 6000 Blackwell, 96 GB VRAM each

**Storage:** Samsung 9100 PRO 8 TB M.2 NVMe SSD, PCIe 5.0

## Contents

- [`grub-setup.md`](grub-setup.md) – GRUB setup, undo installation
- [`base-system.md`](base-system.md) – Debian 13 base installation, system preparation, NVIDIA drivers, and CUDA setup
- [`tensorrt-llm.md`](tensorrt-llm.md) – TensorRT-LLM environment, dependencies, source build, validation, and troubleshooting notes
- [`scripts/`](scripts/) – utility scripts for inspecting and documenting the system environment

## Goal

The repository documents the complete path from a minimal Linux installation to a working local AI inference environment. The focus is on native installations, reproducible steps, transparent configuration, and practical testing without Docker wherever possible.

## Status

This repository is a work in progress. Commands, versions, and procedures may change as the platform evolves.

Use the instructions as a reference and review commands before running them on your own system.

## License

This project is currently provided for documentation and experimentation purposes.
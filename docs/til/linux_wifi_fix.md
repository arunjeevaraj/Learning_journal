# Linux Kernel & Intel WiFi Issues
**Date:** 2025-12-26  
**Tags:** #Linux #Hardware #Fix

## The Problem
Experiencing instability with Intel WiFi drivers on certain kernels.

## The Solution
Disable PCIe Active State Power Management (ASPM) and the iwlwifi power save feature:
* **Command:** `pcie_aspm=off iwlwifi.power_save=0`
* **Note:** This is usually added to the GRUB command line.
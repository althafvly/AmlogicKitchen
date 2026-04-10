<p align="left">
  <img src="logo.png" width="350">
</p>

# AmlogicKitchen

**A universal firmware kitchen for working with Amlogic, Rockchip, and AllWinner images (Linux x86\_64 only).**

---

### 🛠️ Features

**✅ Rockchip Support**

* Unpack and repack Rockchip firmware images.

**✅ Amlogic Support**

* Unpack and repack Amlogic firmware images.
* Generate Amlogic images from supported flashable ZIPs.
* Dump ROMs via mask ROM mode (Only for legacy chips).

**✅ Common Features**

* Unpack and repack partitions.
* Handle `boot`, `recovery`, `logo`, and `dtb` images.
* Unpack and repack super images.
* Sign ROMs with custom keys.

---

### ⚠️ Disclaimer

This project is intended for educational purposes. Use at your own risk.

* The developer is not liable for any **device damage**, **data loss**, **legal issues**, or **injuries**.
* By using this tool, you accept full responsibility for its usage and consequences.

---

### 🔧 Installation

Clone the repository:

```bash
git clone https://github.com/althafvly/AmlogicKitchen AmlogicKitchen
cd AmlogicKitchen
git submodule update --init --recursive
```

Enable 32-bit support and install required dependencies:

```bash
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install libc6:i386 libstdc++6:i386 libgcc1:i386 device-tree-compiler \
python3 7zip android-sdk-libsparse-utils brotli rename libconfuse2
```

---

### 📌 Notes

* DTB compile/decompile may throw some warnings—these can be safely ignored in most cases.
* Compatibility is limited to certain firmwares, devices, and chipsets. Not all images may work.
* Tested primarily on **Linux (Ubuntu)**. While it *might* work on other platforms, full functionality is not guaranteed.
* Most binaries are compiled for **Linux x86\_64** only.

---

### 🙏 Credits

Special thanks to the contributors and original authors of the tools integrated into this kitchen:

* **Vortex** – Base kitchen (vtx\_kitchen)
* **unix3dgforce, blackeange, xiaoxindada** – ImgExtractor
* **osm0sis** – Android Image Kitchen (AIK)
* **LineageOS** – Super image tools, Amlogic DTB/unpack tools
* **xpirt** – `img2sdat`, `sdat2img`
* **Roger Shimizu** – `android-sdk-libsparse-utils`
* **erfanoabdi** – ROM Resigner
* **RedScorpioXDA** – imgRePacker
* **YuzukiTsuru** – OpenixCard
* **Guoxin Pu** – ampack

*And everyone else who contributed—thank you!*

---

### 🐞 Report Issues

Encounter a bug or need help? [Open an issue](https://github.com/xKern/AmlogicKitchen/issues/new)

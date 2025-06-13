<h1 align="center" style="margin-top: 0px;">GlauTude</h1>

<p align="center">
  <img src="https://github.com/user-attachments/assets/c33ff7b1-e599-41a5-ac88-da4f38f7d150" alt="logo" width="800">
</p>

<p align="center"><strong>A CLI YouTube player, without ADS and play in CLI too!</strong></p>

<div align="center">
  <img src="https://img.shields.io/badge/test-passing-green?logo=github" alt="Build Status">
  </a>
  <a href="https://github.com/NammIsADev/OptimizedToolsPlusPlus/releases">
    <img src="https://img.shields.io/badge/version-1.0-gray" alt="Version">
  </a>
  <a href="https://www.codefactor.io/repository/github/nammisadev/glautude"><img src="https://www.codefactor.io/repository/github/nammisadev/glautude/badge" alt="CodeFactor" /></a>
  <a href="https://github.com/NammIsADev/glautude/issues">
    <img src="https://img.shields.io/github/issues/NammIsADev/glautude.svg" alt="Open Issues">
  </
  <a href="https://github.com/NammIsADev/glautude">
    <img src="https://img.shields.io/github/stars/NammIsADev/glautude.svg" alt="GitHub Stars">
  </a>
</div>


## 🏆 About

GlauTude is **your lightweight command line tool** for enjoying YouTube content directly from your terminal. Designed for efficiency and a distraction-free experience, GlauTude leverages powerful open source tools like yt-dlp and mpv (or ConPlayer on Windows) to deliver ad-free video and audio playback. It's ideal for quick media access and for those who prefer the speed and simplicity of the command line.

> [!WARNING]
> *Linux:* For the best results with terminal pixel graphics, ~~**your terminal must support Sixel**~~ **atleast terminal support True Color** (e.g., foot, mlterm, Kitty, etc.).
>
> *Termux:* Playing video directly in the terminal can be resource-intensive, particularly on mobile devices (Termux). You might **experience slower rendering or desynchronization** compared to dedicated video players. For optimal performance, consider playing audio-only or selecting lower video resolutions.
>
> *Windows:* For the best visual experience, it is **highly recommended to use Windows Terminal** from the Microsoft Store.

---

## ✨ Features
- Seamless YouTube Playback: Stream videos or audio directly from a YouTube URL without opening a browser.
- Ad-Free Experience: Enjoy your content without interruptions from advertisements.
- Integrated YouTube Search: Find videos by keywords and play them directly from a convenient list of results.
- (advanced) Flexible Quality Options: Choose specific video quality formats (e.g., 1080p, 720p) or opt for high-quality audio-only playback.
- Automated Dependency Management: On first run, GlauTude intelligently checks for and installs all necessary command-line tools (such as yt-dlp, mpv/ConPlayer, ffmpeg, jq, and terminal video libraries) in a dedicated bin directory, ensuring you're always ready to go.
- In-Terminal Video (Linux/Termux): Experience video playback directly within compatible terminal emulators using mpv's sixel, tct, or caca (ASCII art) outputs, with automatic detection and fallbacks.
- Multi-platform: Supported Windows, Linux and Android (Termux).

---

## 💾 How to use
GlauTude is designed for easy setup and interactive use. Follow these steps to get started on your preferred platform:

### Download the Script
For Windows: 
```batch
curl -L https://raw.githubusercontent.com/NammIsADev/glautude/main/windows/windows.cmd -o windows.cmd
windows.cmd
```
For Linux (Ubuntu/Debian or any apt-based distro):
```bash
curl -L https://raw.githubusercontent.com/NammIsADev/glautude/main/linux/linux.sh -o linux.sh && chmod +x linux.sh && ./linux.sh
```
For Termux (Android): 
```bash
termux-setup-storage && curl -LJO https://raw.githubusercontent.com/NammIsADev/glautude/main/termux-experimental/termux.sh && chmod +x termux.sh && ./termux.sh
```

### Place the Script
It's highly recommended to place the downloaded script in a dedicated, easy-to-access folder (e.g., `Desktop` on Windows, or ~`/GlauTude/` on Linux/Termux). Avoid running the script directly from your temporary system folder (`%TEMP%` on Windows, or `/tmp/` on Linux/Termux)

### Run GlauTude
The first time you run GlauTude, it will automatically detect and install all necessary dependencies (like yt-dlp, mpv/ConPlayer, ffmpeg, jq, etc.) into a `bin` subfolder within the script's directory. This process requires an active internet connection and may take a few moments.

### Interactive Menu
Once launched, GlauTude will present you with an interactive command-line menu:

```
-------------------------------------------------------------------
            GLAUTUDE - Powered by <player> and yt-dlp
-------------------------------------------------------------------

Version: ...

[1] Play video/audio by YouTube URL
[2] Search YouTube Video
[3] Clear Temp (recommended before playback)
[4] Exit

Select an option [1-4]:
```
Option:
- Play video/audio by YouTube URL: Enter a full YouTube URL when prompted. You can then choose audio-only playback or select a specific video quality from the listed formats.
- Search YouTube Video: Enter your search terms, and GlauTude will display a list of top results. Select the number corresponding to the video you wish to play, with options for quality or audio-only.
- Clear Temp: This option helps manage disk space by removing temporary files created during playback. It's recommended to run this periodically.
- Exit: Closes the GlauTude application.

---

## 🎮 Controls
**Linux / Termux (mpv playback)**
When a video/audio is playing, you can use the following keys:

|Keys  |Actions                |
|------|-----------------------|
|Space| Pause / Resume playback|
|q| Quit playback              |
|← / →| Rewind / Fast Forward 5 seconds|
|↓ / ↑| Rewind / Fast Forward 1 minute|
|PgUp / PgDn| Rewind / Fast Forward 10 minutes|
|[ / ]| Decrease / Increase Playback Speed|
|9 / 0| Decrease / Increase Volume|
|m| Mute / Unmute audio         |
|f| Toggle Fullscreen (if supported by terminal/mpv setup)


**Windows (ConPlayer playback)**
ConPlayer offers a minimal set of controls typically through keyboard interaction during playback. Specific controls depend on ConPlayer itself, but general media keys often work.

---

## 📸 Screenshots

![image](https://github.com/user-attachments/assets/378c3049-2158-433a-ba4f-1809e6e43fc2)

*Glautude Linux playing Doja Cat - Say So at 2K*

![image](https://github.com/user-attachments/assets/2213c848-d045-4ed0-b21f-1a4e4a54a389)

*Glautude Windows playing LISA ft. Doja Cat & RAYE at 4K - Born Again*

---

## 📜 License

This project is distributed under the **Unlicense License**.

---

## 💖 Credits
- mpv: https://github.com/mpv-player/mpv
- ffmpeg: https://github.com/FFmpeg/FFmpeg
- ConPlayer: https://github.com/mt1006/ConPlayer
- yt-dlp: https://github.com/yt-dlp/yt-dlp
- 7-zip: https://sourceforge.net/projects/sevenzip/
- ColorTool: https://github.com/microsoft/terminal/tree/main/src/tools/ColorTool

---

## 🤝 Contribute & Feedback

GlauTude is an **open-source project**, and contributions are **highly appreciated**!  

## Made with love 💖

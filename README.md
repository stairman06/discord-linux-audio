# Discord Linux Audio Assistant
Screenshare desktop audio with Discord on Linux!

Credit goes to edisionnano's [excellent guide](https://github.com/edisionnano/Screenshare-with-audio-on-Discord-with-Linux) to getting Discord screenshare audio working. Much of DLAA is based on this guide, including the userscript which is a modification of [the original](https://openuserjs.org/scripts/samantas5855/Screenshare_with_Audio_(virtmic)).

## Dependencies
Make sure you have `dialog` installed
- (Debian/Ubuntu) `sudo apt install dialog`
- (Arch) `sudo pacman -S dialog`
- Other distros: you can figure this out

You also need to be on a system with a PulseAudio implementation installed. If you're using PipeWire, make sure you have `pipewire-pulse`.

## Getting Started
DLAA requires both a Chromium-based browser and a helper script on the local machine.

### Browser
To start, install the userscript into a Chromium-based browser like Chromium, Chrome, or Brave. You can either use a userscript manager or paste the code directly into the console.

**Userscript Manager**  
1) Install a Userscript manager extension. I recommend [Violentmonkey](https://chrome.google.com/webstore/detail/violentmonkey/jinjaccalgkegednnccohejagnlnfdag) because it's open source
2) [Visit the userscript here](https://raw.githubusercontent.com/stairman06/discord-linux-audio/master/dlaa.user.js)
3) Install!

**Console**  
If you don't want to use a userscript manager, you can also paste code directly into the console.
1) Open Discord in your browser
2) Open the devtools by pressing F12 and going to the "Console" tab
3) Paste the [source code](https://raw.githubusercontent.com/stairman06/discord-linux-audio/master/dlaa.user.js) into the console and press Enter

### DLAA Shell Script
Now you need to run the shell script. 
1) [Download the shell script](https://raw.githubusercontent.com/stairman06/discord-linux-audio/master/dlaa.sh)
2) Open a terminal window and navigate to the file
3) Mark the file as executable: `chmod +x dlaa.sh`
4) Run the script `./dlaa.sh`

## Using DLAA
Once you've entered the shell script, a basic interface is presented. Make sure you have the programs you want to stream running and producing audio, so they are visible in the menu.

Select the programs you want to stream through the menu, and now you're ready:
1) Visit Discord's webapp in your browser
2) Go to your User Settings and make sure your microphone input is not set to "Default"
3) Everything's good! Assuming you followed all the steps correctly, you can now stream desktop audio via Discord screen sharing.
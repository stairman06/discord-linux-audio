// ==UserScript==
// @name         DLAA Discord Screenshare with Audio
// @namespace    https://github.com/stairman06
// @version      0.4
// @description  Screenshare with Audio on Discord, modified from the original at https://openuserjs.org/scripts/samantas5855/Screenshare_with_Audio_(virtmic)
// @author       originally by Guest271314, Samantas5855 and Doke, modified by stairman06
// @match        https://*.discord.com/*
// @icon         https://www.google.com/s2/favicons?domain=discord.com
// @grant        none
// @license      MIT
// ==/UserScript==

/* jshint esversion: 8 */

navigator.mediaDevices.chromiumGetDisplayMedia =
  navigator.mediaDevices.getDisplayMedia;

const getAudioDevice = async (nameOfAudioDevice) => {
  try {
    await navigator.mediaDevices.getUserMedia({ audio: true });
  } catch (e) {
    console.error(e);
    alert('[DLAA] Unable to find any audio devices! Check console for details');
    return;
  }
  let devices = await navigator.mediaDevices.enumerateDevices();
  let audioDevice = devices.find(({ label }) => label === nameOfAudioDevice);

  return audioDevice;
};

const getDisplayMedia = async () => {
  let myDiscordAudioSink = await getAudioDevice('dlaa-virtmic');
  if (!myDiscordAudioSink) {
    alert(
      '[DLAA] Virtual Microphone (dlaa-virtmic) not found. Please check that DLAA is configured correctly'
    );
    return;
  }

  let captureSystemAudioStream = await navigator.mediaDevices.getUserMedia({
    audio: {
      // We add our audio constraints here, to get a list of supported constraints use navigator.mediaDevices.getSupportedConstraints();
      // We must capture a microphone, we use default since its the only deviceId that is the same for every Chromium user
      deviceId: { exact: myDiscordAudioSink.deviceId }, //
      // We want auto gain control, noise cancellation and noise suppression disabled so that our stream won't sound bad
      autoGainControl: false,
      echoCancellation: false,
      noiseSuppression: false,
      // By default Chromium sets channel count for audio devices to 1, we want it to be stereo in case we find a way for Discord to accept stereo screenshare too
      //channelCount: 2,
      // You can set more audio constraints here, bellow are some examples
      //latency: 0,
      //sampleRate: 48000,
      //sampleSize: 16,
      //volume: 1.0
    },
  });
  let [track] = captureSystemAudioStream.getAudioTracks();
  const gdm = await navigator.mediaDevices.chromiumGetDisplayMedia({
    video: true,
    audio: true,
  });
  gdm.addTrack(track);
  return gdm;
};
navigator.mediaDevices.getDisplayMedia = getDisplayMedia;

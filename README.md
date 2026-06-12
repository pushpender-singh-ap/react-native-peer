# react-native-peer

[![npm version](https://img.shields.io/npm/v/react-native-peer.svg)](https://www.npmjs.com/package/react-native-peer)
[![license](https://img.shields.io/npm/l/react-native-peer.svg)](./LICENSE)

Use [PeerJS](https://peerjs.com/) in React Native. The full PeerJS API — peer-to-peer **data**, **video**, and **audio** connections over WebRTC — running on top of [`react-native-webrtc`](https://github.com/react-native-webrtc/react-native-webrtc).

PeerJS was built for the browser and depends on browser-only WebRTC APIs that don't exist in React Native. `react-native-peer` patches PeerJS to run on React Native's native WebRTC implementation, so you get the same API you already know — no browser, no `webrtc-adapter`. See [How it works](#how-it-works).

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [Data connection](#data-connection)
  - [Video / audio call](#video--audio-call)
  - [Configuring ICE servers (STUN / TURN)](#configuring-ice-servers-stun--turn)
  - [Using your own PeerServer](#using-your-own-peerserver)
- [API](#api)
- [How it works](#how-it-works)
- [Troubleshooting](#troubleshooting)
- [Building from source](#building-from-source)
- [License](#license)

## Features

- 🔌 **Same PeerJS API** — wraps PeerJS `1.5.5`, so existing PeerJS code and the [official PeerJS docs](https://peerjs.com/docs/) apply directly.
- 💬 **Data connections** — send and receive arbitrary JSON, strings, and binary data between peers.
- 🎥 **Media connections** — peer-to-peer video and audio calls via `react-native-webrtc`.
- 📱 **iOS & Android** — backed by native WebRTC through `react-native-webrtc`.
- 🧩 **TypeScript types included** — re-exported straight from PeerJS.

## Requirements

This package has a **peer dependency on [`react-native-webrtc`](https://github.com/react-native-webrtc/react-native-webrtc)**, which provides the native WebRTC engine. It must be installed and configured for your platform.

| Package | Version |
| --- | --- |
| `react-native-webrtc` | `>= 118` |
| `react-native` | `>= 0.71` |

> **Note:** `react-native-webrtc` contains native code, so it does **not** work in Expo Go. With Expo, use a [development build](https://docs.expo.dev/develop/development-builds/introduction/).

## Installation

Install both packages:

```sh
npm install react-native-peer react-native-webrtc
# or
yarn add react-native-peer react-native-webrtc
```

Then configure `react-native-webrtc` for your platform. Follow its official installation guide — these are the essentials:

**iOS** — install pods and add camera/microphone usage descriptions to `Info.plist`:

```sh
cd ios && pod install && cd ..
```

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for video calls.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for calls.</string>
```

**Android** — add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**Expo** — install with Expo and add the config plugin, then create a development build:

```sh
npx expo install react-native-webrtc
```

```json
{
  "expo": {
    "plugins": ["@config-plugins/react-native-webrtc"]
  }
}
```

See the [`react-native-webrtc` installation docs](https://github.com/react-native-webrtc/react-native-webrtc/blob/master/Documentation/BasicUsage.md) for the complete, up-to-date setup (including data-only builds and runtime permissions on Android).

## Usage

`react-native-peer` exports the same `Peer` class as PeerJS:

```js
import Peer from 'react-native-peer';
// named exports are also available:
// import { Peer, util, PeerError } from 'react-native-peer';
```

### Data connection

Create a peer, then connect to another peer by its ID and exchange data.

```js
import Peer from 'react-native-peer';

const peer = new Peer();
peer.on('error', console.log);

peer.on('open', myId => {
  console.log('My peer ID is', myId);
});

// Outgoing: connect to a known remote peer ID.
function connectTo(remoteId) {
  const conn = peer.connect(remoteId);
  conn.on('error', console.log);
  conn.on('open', () => {
    conn.on('data', data => console.log('Received:', data));
    conn.send('Hello from the connecting peer!');
  });
}

// Incoming: respond to peers that connect to us.
peer.on('connection', conn => {
  conn.on('open', () => {
    conn.on('data', data => console.log('Received:', data));
    conn.send('Hello from the host peer!');
  });
});
```

### Video / audio call

Media streams come from `react-native-webrtc`. Grab a local stream with `mediaDevices.getUserMedia`, pass it to `peer.call()`, and render the remote stream with `RTCView`.

```jsx
import React, { useEffect, useState } from 'react';
import { View } from 'react-native';
import { mediaDevices, RTCView } from 'react-native-webrtc';
import Peer from 'react-native-peer';

export default function VideoCall({ remoteId }) {
  const [remoteStream, setRemoteStream] = useState(null);

  useEffect(() => {
    let peer;
    let localStream;

    (async () => {
      localStream = await mediaDevices.getUserMedia({ audio: true, video: true });
      peer = new Peer();

      // Place a call once our peer is ready.
      peer.on('open', () => {
        const call = peer.call(remoteId, localStream);
        call.on('stream', setRemoteStream);
      });

      // Answer incoming calls with our local stream.
      peer.on('call', call => {
        call.answer(localStream);
        call.on('stream', setRemoteStream);
      });
    })();

    return () => {
      peer?.destroy();
      localStream?.getTracks().forEach(track => track.stop());
    };
  }, [remoteId]);

  return (
    <View style={{ flex: 1 }}>
      {remoteStream && (
        <RTCView streamURL={remoteStream.toURL()} style={{ flex: 1 }} objectFit="cover" />
      )}
    </View>
  );
}
```

### Configuring ICE servers (STUN / TURN)

On real mobile networks you'll almost always need STUN/TURN servers for NAT traversal. Pass them through the standard PeerJS `config` option:

```js
const peer = new Peer({
  config: {
    iceServers: [
      { urls: 'stun:stun.l.google.com:19302' },
      {
        urls: 'turn:your.turn.server:3478',
        username: 'user',
        credential: 'pass',
      },
    ],
  },
});
```

### Using your own PeerServer

By default peers connect through the public PeerJS cloud server. Point them at your own [PeerServer](https://github.com/peers/peerjs-server) with the usual PeerJS options:

```js
const peer = new Peer(undefined, {
  host: 'your.server.com',
  port: 9000,
  path: '/myapp',
  secure: true,
});
```

## API

The API is **identical to PeerJS** — `react-native-peer` re-exports it unchanged. Refer to the official references:

- [PeerJS documentation](https://peerjs.com/docs/)
- [PeerJS API reference](https://peerjs.com/docs/#api)

Available exports (mirroring PeerJS):

`Peer` (default export), `util`, `PeerError`, `MsgPackPeer`, `BufferedConnection`, `StreamConnection`, `MsgPack`, `ConnectionType`, `PeerErrorType`, `BaseConnectionErrorType`, `DataConnectionErrorType`, `SerializationType`, `SocketEventType`, `ServerMessageType`.

## How it works

PeerJS targets the browser: it relies on [`webrtc-adapter`](https://github.com/webrtcHacks/adapter) and the global `RTCPeerConnection`, `RTCIceCandidate`, and `RTCSessionDescription` objects, none of which exist in React Native.

At build time (see [`build.sh`](./build.sh)), this package:

1. Clones PeerJS `v1.5.5`.
2. Applies [`decoupling.diff`](./decoupling.diff), which removes the `webrtc-adapter` dependency and its browser-detection logic (React Native always uses the native WebRTC engine).
3. Bundles PeerJS into a single ES module with Parcel.
4. Prepends imports of `RTCPeerConnection`, `RTCIceCandidate`, and `RTCSessionDescription` from `react-native-webrtc`, so PeerJS resolves them to React Native's native implementations instead of missing browser globals.

The result is the full PeerJS API running on React Native's native WebRTC, with no browser shims.

## Troubleshooting

- **`Unable to resolve module react-native-webrtc`** — `react-native-webrtc` is a required peer dependency. Install it and rebuild the native app (`pod install` on iOS).
- **Calls connect then immediately drop / no media flows** — you're likely behind a NAT without a reachable TURN server. Add [ICE servers](#configuring-ice-servers-stun--turn).
- **Nothing happens in Expo Go** — `react-native-webrtc` needs native code. Use an [Expo development build](https://docs.expo.dev/develop/development-builds/introduction/).
- **Camera/microphone permission denied** — confirm the iOS `Info.plist` keys and Android manifest permissions above, and request runtime permissions on Android.

## Building from source

The published `dist/` bundle is generated by [`build.sh`](./build.sh), which requires `git`, `node`, and `bash`:

```sh
npm install
npm run build   # produces dist/react-native-peer.js
```

## License

MIT © [Pushpender Singh](https://github.com/pushpender-singh-ap)

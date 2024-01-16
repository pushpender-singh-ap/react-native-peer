# react-native-peer

A React Native wrapper for [PeerJS](https://peerjs.com/). PeerJS simplifies WebRTC peer-to-peer data, video, and audio calls.

## Getting started

### To install and start using react-native-peer

```sh
npm install react-native-peer
```

## Usage

To use react-native-peer, `import` the `react-native-peer` module and use the `Peer`.

Here is an example of basic usage:

```js
import Peer from 'react-native-peer';

const globalPeer = new Peer();
globalPeer.on('error', console.log);

globalPeer.on('open', globalPeerID => {
  console.log('Local peer open with ID', globalPeerID);

  const remotePeer = new Peer();
  remotePeer.on('error', console.log);
  remotePeer.on('open', remotePeerId => {
    console.log('Remote peer open with ID', remotePeerId);

    const conn = remotePeer.connect(globalPeerID);
    conn.on('error', console.log);
    conn.on('open', () => {
      console.log('Remote peer has opened connection.');
      console.log('conn', conn);
      conn.on('data', data => console.log('Received from local peer', data));
      console.log('Remote peer sending data.');
      conn.send('Hello, this is the REMOTE peer!');
    });
  });
});

globalPeer.on('connection', conn => {
  console.log('Local peer has received connection.');
  conn.on('error', console.log);
  conn.on('open', () => {
    console.log('Local peer has opened connection.');
    console.log('conn', conn);
    conn.on('data', data => console.log('Received from remote peer', data));
    console.log('Local peer sending data.');
    conn.send('Hello, this is the LOCAL peer!');
  });
});

```

## License

MIT

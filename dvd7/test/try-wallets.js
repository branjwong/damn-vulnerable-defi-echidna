const ethers = require('ethers');

const wallets = [];
const matches = [];

const sources = [
  "0xA73209FB1a42495120166736362A1DfA9F95A105",
  "0xe92401A4d3af5E446d93D11EEc806b1462b39D15",
  "0x81A5D6E50C214044bE44cA0CB057fe119097850c",

  // random wallet
  "0xD956B2dF840B82cfF54cf0eB465eE08e844C1ed4"
];

const leakToPrivateKey = (leak) => {
  const base64 = Buffer.from(leak.split(` `).join(``), `hex`).toString(`utf8`)
  const hexKey = Buffer.from(base64, `base64`).toString(`utf8`)
  console.log({ leak, base64, hexKey })
  return hexKey
}

// Leaked information to format
const leakedInformation = [
  '4d 48 68 6a 4e 6a 63 34 5a 57 59 78 59 57 45 30 4e 54 5a 6b 59 54 59 31 59 7a 5a 6d 59 7a 55 34 4e 6a 46 6b 4e 44 51 34 4f 54 4a 6a 5a 47 5a 68 59 7a 42 6a 4e 6d 4d 34 59 7a 49 31 4e 6a 42 69 5a 6a 42 6a 4f 57 5a 69 59 32 52 68 5a 54 4a 6d 4e 44 63 7a 4e 57 45 35',
  '4d 48 67 79 4d 44 67 79 4e 44 4a 6a 4e 44 42 68 59 32 52 6d 59 54 6c 6c 5a 44 67 34 4f 57 55 32 4f 44 56 6a 4d 6a 4d 31 4e 44 64 68 59 32 4a 6c 5a 44 6c 69 5a 57 5a 6a 4e 6a 41 7a 4e 7a 46 6c 4f 54 67 33 4e 57 5a 69 59 32 51 33 4d 7a 59 7a 4e 44 42 69 59 6a 51 34',
]

leakedInformation.forEach((leak) => {
  const privateKey = leakToPrivateKey(leak);
  const wallet = new ethers.Wallet(privateKey);
  wallets.push(wallet);
});

wallets.forEach((wallet) => {
  sources.forEach((source) => {
    if (wallet.address === source) {
      matches.push(wallet);
    }
  });
});

matches.forEach((match) => {
  console.log(`Match found: ${match.address}`);
  console.log(`Private Key: ${match.privateKey}`);
});

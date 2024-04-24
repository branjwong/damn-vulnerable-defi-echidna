# Damn Vulnerable Defi Echidna Exercises

> This repo is meant to be used with exercises 5 and 6 of [Building-secure-contracts/Echidna](https://github.com/crytic/building-secure-contracts/tree/master/program-analysis/echidna).

# Quickstart

```sh
make init
make ln

cd repo
npm install
```

# Process to learn invariant testing

1. Manual review, find bug
2. Create POC
3. Create a simple invariant test that does POC's method that proves issue, with access to one subroutine that conducts the exploit
4. Untangle the subroutine so the fuzzer has access to as many of the calling contracts methods as possible

# Echidna Exercise to DVD Mapping

| Echidna | Damn Vulnerable # | Name           | Uniswap |
| ------- | ----------------- | -------------- | ------- |
| 5       | 2                 | Naive receiver |         |
| 6       | 1                 | Unstoppable    |         |
| 7       | 4                 | Side Entrance  |         |
| 8       | 5                 | The Rewarder   |         |
|         | 3                 | Truster        |         |
|         | 6                 | Selfie         |         |
|         | 7                 | Compromised    |         |
|         | 8                 | Puppet         | x       |
|         | 9                 | Puppet V2      | x       |
|         | 10                | Free Rider     | x       |
|         | 11                | Backdoor       |         |
|         | 12                | Climber        |         |
|         | 13                | Wallet Mining  |         |
|         | 14                | Puppet V3      | x       |
|         | 15                | ABI Smuggling  |         |

# This creates the Haskell package set.
# https://input-output-hk.github.io/haskell.nix/user-guide/projects/
haskell-nix: src: inputMap: haskell-nix.cabalProject' {
  inherit inputMap;
  name = "ogmios";
  src = haskell-nix.haskellLib.cleanSourceWith {
    name = "ogmios-src";
    inherit src;
    subDir = "server";
    filter = path: type:
      builtins.all (x: x) [
        (baseNameOf path != "package.yaml")
      ];
  };

  cabalProjectLocal = ''
    index-state:
      -- set the latest hackages and CHaP index states
      , hackage.haskell.org 2024-05-23T22:20:49Z
      , cardano-haskell-packages 2024-05-21T10:43:27Z

    constraints:
      -- Avoid `Setup.hs:75:30: error: [GHC-83865]`
      -- Seemingly due to the freeze containing two cabal version which builds are made for:
      -- any.Cabal ==3.10.3.0 || ==3.12.0.0
      , Cabal == 3.10.3.0

      -- Avoid `src/Control/Monad/Class/MonadSTM/Trans.hs:662:5: error: [GHC-54721]`
      -- Git issue:
      -- , io-classes-mtl == 0.1.1.0
  '';

  sha256map = {
    # ogmios repo cabal.project missing srp nix hashes
    "https://github.com/CardanoSolutions/cardano-ledger"."837089f9b253c8a51b93a039b7e656e8ca5b6b70" = "sha256-tND3yRSaWqDnI8HVrj1FzvVg0umWQSFRhcRNuSecc+Y=";
  };

  # Ogmios repo server/modules/fast-bech32/fast-bech32.cabal requires base >=4.17 && <5
  # Ogmios dep tree-diff requires base < 4.20
  #
  # This leaves ghc948, ghc965, ghc982 as options:
  #   ghc948: fails to build src/ouroboros-consensus/Ouroboros/Consensus/Block/RealPoint.hs:97:65: error: Could not deduce (HasHeader blk)
  #   ghc965: builds
  #   ghc982: builds
  compiler-nix-name = "ghc982";

  modules = [
    {
      doHaddock = false;
      doCheck = false;
    }
    ({ pkgs, ... }: {
      # Use the VRF fork of libsodium
      packages = {
        cardano-crypto-praos.components.library.pkgconfig = pkgs.lib.mkForce [
          [ pkgs.libsodium-vrf ]
        ];
        cardano-crypto-class.components.library.pkgconfig = pkgs.lib.mkForce [
          [ pkgs.libsodium-vrf pkgs.secp256k1 pkgs.libblst ]
        ];
      };
    })
  ];
}

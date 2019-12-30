{ nixpkgs ? import <nixpkgs> {}, compiler ? "default", doBenchmark ? false }:

let

  inherit (nixpkgs) pkgs;

  f = { mkDerivation, aeson, async, base, bloomfilter, bytestring
      , conduit, feed, hslogger, irc-conduit, microlens, network
      , optparse-applicative, stdenv, stm, text, wreq
      }:
      mkDerivation {
        pname = "brockman";
        version = "1.2.2";
        src = ./.;
        isLibrary = false;
        isExecutable = true;
        executableHaskellDepends = [
          aeson async base bloomfilter bytestring conduit feed hslogger
          irc-conduit microlens network optparse-applicative stm text wreq
        ];
        license = stdenv.lib.licenses.mit;
      };

  haskellPackages = if compiler == "default"
                       then pkgs.haskellPackages
                       else pkgs.haskell.packages.${compiler};

  variant = if doBenchmark then pkgs.haskell.lib.doBenchmark else pkgs.lib.id;

  drv = variant (haskellPackages.callPackage f {});

in

  if pkgs.lib.inNixShell then drv.env else drv

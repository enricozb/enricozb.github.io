{ pkgs ? import <nixpkgs> { } }:

let
  blog = pkgs.writeShellScriptBin "blog" ''
    python ${./server/server.py} "$1"
  '';

in pkgs.mkShell { nativeBuildInputs = with pkgs; [ blog typst ]; }

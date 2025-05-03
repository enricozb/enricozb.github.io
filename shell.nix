{ pkgs ? import <nixpkgs> { } }:

let
  blog = pkgs.writeShellScriptBin "blog" ''
    set -e

    python3 -m http.server 1234 &
    HTTP_PID=$!

    # killed python on script exit
    cleanup() {
        echo "stopping HTTP server (PID $HTTP_PID)..."
        kill $HTTP_PID
    }
    trap cleanup EXIT

    typst watch --features html --format html "$1" --root .
  '';

in pkgs.mkShell { nativeBuildInputs = with pkgs; [ blog typst ]; }

{
  description = "Minería de Datos 2027-1 — dev environment (uv + Python 3.13 + JDK for PySpark)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Nix-built interpreter: correctly patched for NixOS out of the box,
        # unlike the standalone builds uv would otherwise try to download.
        python = pkgs.python313;

        # Shared libs that manylinux wheels (numpy, pandas, scikit-learn,
        # pyarrow inside pyspark, matplotlib, ...) dynamically link against
        # at runtime. Add to this list if `uv sync` installs something that
        # later fails to import with "cannot open shared object file".
        libs = with pkgs; [
          stdenv.cc.cc.lib # libstdc++.so.6
          zlib # libz.so — numpy, pandas
          openssl
          libffi
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          name = "data-mining";

          packages = [
            python
            pkgs.uv
            pkgs.jdk21 # pyspark>=4.2.0 needs Java 17/21/25 (Spark 4.0 dropped 8/11)
          ];

          # Stop uv from downloading its own Python. uv's managed builds
          # (python-build-standalone) are plain generic-Linux binaries and
          # can't start on NixOS — there's no /lib64/ld-linux-x86-64.so.2.
          # Pointing UV_PYTHON at the interpreter Nix already built correctly
          # for this system sidesteps the problem entirely (no nix-ld or
          # system-level config needed for this repo).
          UV_PYTHON = "${python}/bin/python3.13";
          UV_PYTHON_DOWNLOADS = "never";

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libs;

          shellHook = ''
            echo "data-mining dev shell — $(python3 --version), $(java -version 2>&1 | head -n1)"
          '';
        };
      });
}

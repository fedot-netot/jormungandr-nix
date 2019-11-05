{ mkYarnPackage, mkYarnModules, stdenv, nodejs, yarn, python, js-chain-libs }:
let
  inherit (stdenv) lib;

  src = js-chain-libs + "/examples/explorer";
in rec {
  jormungandr-explorer = { configJSON ? ../config.json }: stdenv.mkDerivation {
    name = "jormungandr-explorer";
    inherit src;

    nativeBuildInputs = [ react-scripts yarn ];

    buildPhase = ''
      ln -s ${react-scripts}/libexec/jormungandr-explorer/node_modules/
      cp ${configJSON} src/config.json
      yarn run relay
      yarn run build
    '';

    installPhase = ''
      cp -r build $out
    '';
  };

  yarn-modules = mkYarnModules {
    name = "jormungandr-explorer";
    pname = "jormungandr-explorer";
    version = "0.1.0";

    packageJSON = ../package.json;
    yarnLock = ../yarn.lock;
  };

  react-scripts = mkYarnPackage {
    name = "react-scripts";
    inherit src;
    inherit nodejs;

    packageJSON = ../package.json;
    yarnLock = ../yarn.lock;

    publishBinsFor = ["react-scripts" "relay-compiler"];

    yarnPreBuild = ''
      mkdir -p $HOME/.node-gyp/${nodejs.version}
      echo 9 > $HOME/.node-gyp/${nodejs.version}/installVersion
      ln -sfv ${nodejs}/include $HOME/.node-gyp/${nodejs.version}
    '';

    pkgConfig = {
      node-sass = {
        buildInputs = [ python ];
        postInstall = ''
          ${nodejs}/lib/node_modules/npm/bin/node-gyp-bin/node-gyp configure
          ${nodejs}/lib/node_modules/npm/bin/node-gyp-bin/node-gyp build
          mkdir -p vendor/linux-x64-72
          mv build/Release/binding.node vendor/linux-x64-72/binding.node
        '';
      };
    };
  };
}

{
  description = "Coremail Ubuntu client repackaged for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      coremail = pkgs.callPackage ./package.nix { };
      app = {
        type = "app";
        program = "${coremail}/bin/coremail";
        meta.description = "Launch the Coremail email client";
      };
    in
    {
      packages.${system} = {
        inherit coremail;
        default = coremail;
      };
      apps.${system} = {
        coremail = app;
        default = app;
      };
      overlays.default = final: _prev: {
        coremail = final.callPackage ./package.nix { };
      };
      formatter.${system} = pkgs.nixfmt;
    };
}

{
  inputs = {
    # nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixvim
    nixvim-config.url = "github:Myxogastria0808/nix-flakes-nixvim";
  };

  outputs =
    inputs:
    let
      systems = "x86_64-linux";
    in
    {
      ## home-manager ##
      homeConfigurations = {
        linux = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            system = systems;
            # Enable unfree pkgs
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit inputs;
            username = "hello";
            system = systems;
          };
          modules = [
            ./home/home.nix
          ];
        };
      };
    };
}

{
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      user = {
        name = "Myxogastria0808";
        email = "r.rstudio.c@gmail.com";
      };
      credential."https://github.com".helper = "!gh auth git-credential";
      ghq.root = "~/src";
    };
  };
  programs.gh.enable = true;
  programs.gh.gitCredentialHelper.enable = false;
  programs.lazygit.enable = true;
}

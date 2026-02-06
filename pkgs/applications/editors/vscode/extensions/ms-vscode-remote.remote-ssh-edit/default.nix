{ lib, vscode-utils }:

vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "remote-ssh-edit";
    publisher = "ms-vscode-remote";
    version = "0.87.0";
    hash = "sha256-yeX6RAJl07d+SuYyGQFLZNcUzVKAsmPFyTKEn+y3GuM=";
  };
  meta = {
    description = "Visual Studio Code extension that complements the Remote SSH extension with syntax colorization, keyword intellisense, and simple snippets when editing SSH configuration files";
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh-edit";
    homepage = "https://code.visualstudio.com/docs/remote/ssh";
    license = lib.licenses.unfree;
    maintainers = [ lib.maintainers.pandapip1 ];
  };
}

{ lib, vscode-utils }:

vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "markdown-editor";
    publisher = "zaaack";
    version = "0.1.13";
    hash = "sha256-Si8/piNNktcyRY8o8o9my9sP9NEwrNuySVjlyadDjtU=";
  };
  meta = {
    description = "Visual Studio Code extension for WYSIWYG markdown editing";
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=zaaack.markdown-editor";
    homepage = "https://github.com/zaaack/vscode-markdown-editor";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.pandapip1 ];
  };
}

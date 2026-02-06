{ lib, vscode-utils }:

vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "github-markdown-preview";
    publisher = "bierner";
    version = "0.3.0";
    hash = "sha256-7pbl5OgvJ6S0mtZWsEyUzlg+lkUhdq3rkCCpLsvTm4g=";
  };
  meta = {
    description = "VSCode extension that changes the markdown preview to support GitHub markdown features";
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=bierner.github-markdown-preview";
    homepage = "https://github.com/mjbvz/vscode-github-markdown-preview";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.pandapip1 ];
  };
}

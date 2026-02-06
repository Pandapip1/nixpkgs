{ lib, vscode-utils }:

vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "pandoc-markdown-syntax";
    publisher = "garlicbreadcleric";
    version = "0.0.2";
    hash = "sha256-YAMH5smLyBuoTdlxSCTPyMIKOWTSIdf2MQVZuOO2V1w=";
  };
  meta = {
    description = "VSCode extension that adds syntax highlighting for Pandoc-flavored Markdown";
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=garlicbreadcleric.pandoc-markdown-syntax";
    homepage = "https://github.com/garlicbreadcleric/vscode-pandoc-markdown";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.pandapip1 ];
  };
}

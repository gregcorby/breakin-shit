# breakin-shit

## Zapper MCP Server

This repository includes configuration for the Zapper MCP (Model Context Protocol) server, which provides access to enterprise-grade blockchain data across 50+ chains.

### Installation

The Zapper MCP server is configured in `mcp-servers.json`.

To use this with Claude Desktop, add the following to your Claude Desktop configuration file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
**Linux**: `~/.config/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "zapper": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://mcp.zapper.xyz"
      ],
      "env": {
        "ZAPPER_API_KEY": "adfc2303-ad0d-4691-a090-6a10da47c126"
      }
    }
  }
}
```

### Usage

Once configured, Claude Desktop will have access to Zapper's blockchain data API, allowing you to:
- Query token balances and portfolios across 50+ chains
- Access DeFi protocol data
- Retrieve transaction history
- Analyze NFT holdings
- And more

### Resources

- [Zapper MCP Documentation](https://build.zapper.xyz/mcp)
- [Zapper Protocol](https://protocol.zapper.xyz)
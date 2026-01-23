# AURA Quick Start Guide

## Prerequisites
- Node.js 18+
- npm or yarn

## Installation

Run the following commands in separate terminals to set up each component:

### 1. Smart Contracts
```bash
cd contracts
npm install
npx hardhat compile
```

### 2. Backend
```bash
cd backend
npm install
npm start
```

### 3. Frontend
```bash
cd frontend
npm install
npm run dev
```

### 4. MCP Server
```bash
cd mcp-server
npm install
npm run build
```

## Project Structure
- `contracts/`: Hardhat project for Smart Contracts (AgentWallet, CircuitBreaker)
- `backend/`: Node.js Express server for Orchestrator
- `frontend/`: React Vite application for Dashboard
- `mcp-server/`: Model Context Protocol server for AI integration

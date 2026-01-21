# AURA Product Structure

## 📦 Project Architecture

```
aura/
├── contracts/                          # Smart Contracts Layer
│   ├── core/
│   │   ├── AgentWallet.sol            # Account Abstraction + Session Keys
│   │   ├── CircuitBreaker.sol         # Safety guardrails
│   │   └── BatchSettlement.sol        # x402 Multi-leg settlement
│   ├── interfaces/
│   │   ├── IAgentWallet.sol
│   │   ├── ICircuitBreaker.sol
│   │   └── IX402Handler.sol
│   ├── integrations/
│   │   ├── VVSIntegration.sol         # VVS DEX swaps
│   │   ├── MoonlanderIntegration.sol  # Perps platform
│   │   └── USDCHandler.sol            # EIP-3009 gasless payments
│   ├── test/
│   │   ├── AgentWallet.test.ts
│   │   ├── CircuitBreaker.test.ts
│   │   └── BatchSettlement.test.ts
│   ├── deploy/
│   │   ├── deploy.ts
│   │   ├── cronos-testnet.config.ts
│   │   └── cronos-mainnet.config.ts
│   └── hardhat.config.ts
│
├── backend/                            # Node.js/TypeScript Services
│   ├── src/
│   │   ├── core/
│   │   │   ├── AgentOrchestrator.ts    # Main AI agent controller
│   │   │   ├── IntentParser.ts         # Mission parsing
│   │   │   └── ExecutionEngine.ts      # Workflow execution
│   │   │
│   │   ├── settlement/
│   │   │   ├── X402SessionManager.ts   # x402 payment batching
│   │   │   ├── BatchBuilder.ts         # Multi-leg tx bundling
│   │   │   └── PaymentProcessor.ts     # Payment orchestration
│   │   │
│   │   ├── integrations/
│   │   │   ├── VVSClient.ts            # VVS DEX API
│   │   │   ├── MoonlanderClient.ts     # Moonlander perps API
│   │   │   ├── CDCClient.ts            # Crypto.com Exchange real-time data
│   │   │   ├── AgentSDK.ts             # Crypto.com AI Agent SDK wrapper
│   │   │   └── BlockchainProvider.ts   # Cronos zkEVM provider
│   │   │
│   │   ├── safety/
│   │   │   ├── CircuitBreakerManager.ts # Spend limits enforcement
│   │   │   ├── PolicyValidator.ts       # Policy rule checking
│   │   │   └── RiskAssessment.ts        # Risk scoring
│   │   │
│   │   ├── mcp/
│   │   │   ├── MCPServer.ts             # MCP server base
│   │   │   └── CDCMarketDataServer.ts   # Real-time market data provider
│   │   │
│   │   ├── debugging/
│   │   │   ├── BlackBoxDebugger.ts      # AI thought logging
│   │   │   ├── AuditTrail.ts            # Transaction + reasoning audit log
│   │   │   └── DebugDashboard.ts        # Real-time debug UI
│   │   │
│   │   ├── recovery/
│   │   │   ├── ErrorDetector.ts         # Failure detection
│   │   │   ├── RouteRecalculator.ts     # Alternative path finding
│   │   │   └── RetryEngine.ts           # Self-healing retry logic
│   │   │
│   │   ├── api/
│   │   │   ├── routes/
│   │   │   │   ├── agents.ts            # Agent management
│   │   │   │   ├── missions.ts          # Mission creation/tracking
│   │   │   │   ├── settlements.ts       # Settlement history
│   │   │   │   └── audit.ts             # Audit trail queries
│   │   │   └── middleware/
│   │   │       ├── auth.ts
│   │   │       └── validation.ts
│   │   │
│   │   ├── db/
│   │   │   ├── models/
│   │   │   │   ├── Agent.ts
│   │   │   │   ├── Mission.ts
│   │   │   │   ├── Settlement.ts
│   │   │   │   └── AuditLog.ts
│   │   │   └── schemas/
│   │   │       └── postgres.sql
│   │   │
│   │   ├── config/
│   │   │   ├── env.ts
│   │   │   ├── agents.config.ts         # Agent configurations
│   │   │   └── safety.config.ts         # Circuit breaker rules
│   │   │
│   │   └── index.ts
│   │
│   ├── tests/
│   │   ├── unit/
│   │   ├── integration/
│   │   └── e2e/
│   │
│   ├── .env.example
│   ├── package.json
│   ├── tsconfig.json
│   └── docker-compose.yml
│
├── frontend/                           # Dashboard & Monitoring
│   ├── src/
│   │   ├── pages/
│   │   │   ├── Dashboard.tsx            # Agent status + performance
│   │   │   ├── MissionCreator.tsx       # Mission UI
│   │   │   ├── SettlementHistory.tsx    # Transaction history
│   │   │   ├── BlackBoxDebugger.tsx     # Real-time AI reasoning
│   │   │   └── Analytics.tsx            # KPIs + metrics
│   │   │
│   │   ├── components/
│   │   │   ├── AgentCard.tsx
│   │   │   ├── MissionTracker.tsx
│   │   │   ├── TransactionFlow.tsx
│   │   │   ├── AuditLog.tsx
│   │   │   └── RiskGauge.tsx
│   │   │
│   │   ├── api/
│   │   │   └── client.ts                # API client
│   │   │
│   │   └── App.tsx
│   │
│   ├── package.json
│   ├── vite.config.ts
│   └── tsconfig.json
│
├── mcp-server/                         # Model Context Protocol Server
│   ├── src/
│   │   ├── server.ts                   # MCP base server
│   │   ├── resources/
│   │   │   ├── MarketDataResource.ts    # CDC market data
│   │   │   └── AgentStateResource.ts    # Agent status
│   │   ├── tools/
│   │   │   ├── GetMarketPrice.ts        # Real-time pricing
│   │   │   ├── GetOrderBook.ts          # Order book depth
│   │   │   └── ExecuteSwap.ts           # Swap tool for AI
│   │   └── index.ts
│   │
│   ├── package.json
│   └── tsconfig.json
│
├── sdk/                                # TypeScript SDK for Developers
│   ├── src/
│   │   ├── client/
│   │   │   ├── AuraClient.ts            # Main SDK class
│   │   │   └── types.ts                 # TypeScript types
│   │   │
│   │   ├── agent/
│   │   │   ├── AgentBuilder.ts          # Fluent API for agent creation
│   │   │   ├── Mission.ts               # Mission interface
│   │   │   └── Policy.ts                # Safety policy builder
│   │   │
│   │   ├── settlement/
│   │   │   └── x402Client.ts            # x402 payment client
│   │   │
│   │   └── index.ts
│   │
│   ├── examples/
│   │   ├── basic-agent.ts               # Minimal agent example
│   │   ├── advanced-settlement.ts       # Multi-leg settlement
│   │   └── self-healing.ts              # Error recovery example
│   │
│   ├── package.json
│   └── tsconfig.json
│
├── docs/                               # Documentation
│   ├── ARCHITECTURE.md                 # System design
│   ├── QUICK_START.md                  # Getting started
│   ├── API.md                          # API reference
│   ├── SMART_CONTRACTS.md              # Contract docs
│   ├── MCP_INTEGRATION.md               # MCP server guide
│   ├── SAFETY_MODEL.md                 # Circuit breaker + policies
│   ├── DEBUGGING.md                    # Black box debugger guide
│   └── DEPLOYMENT.md                   # Deployment guide
│
├── docker-compose.yml                  # Local dev environment
├── package.json                        # Monorepo root
├── tsconfig.json                       # TypeScript config
├── .env.example                        # Environment template
├── .gitignore
└── README.md
```

---

## 🔄 Data Flow Architecture

```
AI Agent (Crypto.com SDK)
    ↓
    └─→ [Agent Orchestrator] → Parses Mission Intent
           ↓
           ├─→ [CDC Client] → Fetches Real-Time Market Data
           ├─→ [VVS Client] → Query swap rates
           └─→ [Moonlander Client] → Fetch perp pricing
                ↓
           [Execution Engine] → Plans optimal route
                ↓
           [Risk Assessment] → Calculates risk score
                ↓
           [Policy Validator] → Checks mission against policies
                ↓
           [Circuit Breaker] → Enforces spend limits
                ↓
           [Black Box Debugger] → Logs every decision
                ↓
           [Batch Builder] → Bundles multi-leg transactions
                ↓
           [x402 Session Manager] → Creates 1 x402 session for all legs
                ↓
           [Settlement Orchestrator]
                ├─→ Step 1: Fetch CDC Data (cost: $0.01)
                ├─→ Step 2: Swap USDC→CRO on VVS (cost: gas)
                ├─→ Step 3: Open hedge on Moonlander (cost: gas)
                └─→ Step 4: Pay Validator Agent (cost: $0.02)
                ↓
           [All 4 steps paid via 1 x402 session] ← 40% gas savings
                ↓
           [Audit Trail] → Logs tx hash + AI reasoning
                ↓
           [Error Detector] → Monitors for failures
                ├─ If failure: [Route Recalculator] → Find alternative
                └─ [Retry Engine] → Auto-execute recovery

           [Dashboard/API] → Reports to user/external systems
```

---

## 🎯 Core Components Deep Dive

### 1. AgentWallet Smart Contract
```solidity
// Manages:
// - Session Keys (zkEVM Account Abstraction)
// - Autonomous transaction execution
// - Policy enforcement
```

### 2. Circuit Breaker
```solidity
// Hard limits:
// - Max $50 per x402 request
// - Max $500 per mission
// - Prevents uncontrolled spending
```

### 3. Batch Settlement
```solidity
// Atomic operations:
// - 1 x402 session ≈ 4 linked transactions
// - All-or-nothing execution
// - 40% gas reduction
```

### 4. CDC-Market-Data-MCP Server
```typescript
// Provides to AI Agent:
// - Real-time BTC/ETH/CRO prices
// - Order book depth
// - Volatility data
// - 24h volume
```

### 5. Black Box Debugger
```typescript
// Logs for transparency:
// {
//   agent: "hedge-bot-001",
//   timestamp: "2026-01-21T10:30:00Z",
//   thought: "Volatility 25% > threshold (20%), hedging now",
//   action: "BUY_PERP_HEDGE",
//   cost: "$0.05",
//   tx_hash: "0xabc...",
//   result: "success"
// }
```

### 6. Self-Healing Engine
```typescript
// On failure:
// 1. Detect: "Slippage 3% > limit (1%)"
// 2. Recalculate: "Use VVS pool B instead"
// 3. Retry: "Execute backup route"
// 4. Log: "Recovered from failure, continuing mission"
```

---

## 📊 Technology Stack

| Layer | Technology |
|-------|-----------|
| **Smart Contracts** | Solidity 0.8.x, Hardhat, OpenZeppelin |
| **Backend** | Node.js, TypeScript, Express |
| **Database** | PostgreSQL, Redis |
| **Frontend** | React, Vite, TailwindCSS |
| **Blockchain RPC** | Cronos zkEVM, ethers.js |
| **MCP** | Model Context Protocol SDK |
| **AI Integration** | Crypto.com AI Agent SDK |
| **Deployment** | Docker, GitHub Actions |

---

## 🚀 Development Phases

### Phase 1: Foundation (Weeks 1-2)
- [ ] Smart contracts (AgentWallet, Circuit Breaker, Batch Settlement)
- [ ] Cronos zkEVM deployment
- [ ] Backend core services

### Phase 2: Integration (Weeks 3-4)
- [ ] x402 Session Manager
- [ ] CDC-Market-Data-MCP Server
- [ ] VVS + Moonlander integrations

### Phase 3: Intelligence (Week 5)
- [ ] Agent Orchestrator
- [ ] Self-Healing Engine
- [ ] Black Box Debugger

### Phase 4: Polish (Week 6)
- [ ] Dashboard + Analytics
- [ ] SDK + Examples
- [ ] Testing + Deployment
- [ ] Documentation

---

## 📝 Key Files to Create First

1. **Smart Contracts**: `contracts/core/AgentWallet.sol`
2. **Backend**: `backend/src/core/AgentOrchestrator.ts`
3. **MCP Server**: `mcp-server/src/server.ts`
4. **Debugger**: `backend/src/debugging/BlackBoxDebugger.ts`
5. **API Server**: `backend/src/api/routes/agents.ts`
6. **Frontend**: `frontend/src/pages/Dashboard.tsx`

---

## 🎖️ Success Metrics

- ✅ Gas savings: Prove 40% reduction vs single transactions
- ✅ Autonomy: Agent completes 10 missions without human intervention
- ✅ Safety: Circuit Breaker prevents any overspend
- ✅ Transparency: Audit trail shows every AI decision
- ✅ Speed: Batch settlement completes in <30 seconds

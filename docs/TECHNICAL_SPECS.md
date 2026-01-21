# AURA Technical Specifications

## 🏗️ System Architecture

### High-Level Components

```
┌─────────────────────────────────────────────────────────────┐
│                    User / External System                    │
└─────────────────────────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────┐
│                  AURA Frontend Dashboard                     │
│  (Agent Management, Mission Creator, Audit Trail Viewer)    │
└─────────────────────────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────┐
│                    AURA REST API Server                      │
│  (Express.js, TypeScript)                                    │
│  ├─ POST /agents (create agent)                             │
│  ├─ POST /missions (create mission)                         │
│  ├─ GET /audit-trail (query reasoning logs)                │
│  └─ WS /debug-stream (real-time debugger)                   │
└─────────────────────────────────────────────────────────────┘
                             ↓
        ┌────────────────────┬────────────────────┐
        ↓                    ↓                    ↓
┌──────────────┐   ┌──────────────────┐  ┌───────────────┐
│ AI Agent     │   │ MCP Server       │  │ Settlement    │
│ (Crypto.com) │   │ (CDC Market Data)│  │ Orchestrator  │
└──────────────┘   └──────────────────┘  └───────────────┘
        ↓                    ↓                    ↓
        └────────────────────┬────────────────────┘
                             ↓
        ┌────────────────────┴────────────────────┐
        ↓                                         ↓
┌──────────────────────────┐         ┌──────────────────────────┐
│  Cronos zkEVM Smart      │         │  External Integrations   │
│  Contracts               │         │                          │
│ ├─ AgentWallet          │         ├─ VVS DEX (swaps)        │
│ ├─ CircuitBreaker       │         ├─ Moonlander (perps)     │
│ ├─ BatchSettlement      │         ├─ CDC Exchange (prices)  │
│ └─ USDCHandler          │         └─ x402 Facilitator       │
└──────────────────────────┘         └──────────────────────────┘
```

---

## 🔌 API Specifications

### Agent Management

**POST `/api/agents`**
```typescript
Request:
{
  name: "hedge-bot-001",
  owner: "0x1234...",
  policy: {
    maxSpendPerRequest: "50",  // USD
    maxSpendPerMission: "500", // USD
    maxRequestsPerMinute: 10,
    allowedDEXs: ["VVS"],
    allowedStrategies: ["hedge", "arbitrage"]
  },
  initialBalance: "1000" // USDC
}

Response:
{
  agentId: "agent-123",
  walletAddress: "0xabcd...",
  sessionKeyAddress: "0xef01...",
  status: "active",
  createdAt: "2026-01-21T10:00:00Z"
}
```

**POST `/api/missions`**
```typescript
Request:
{
  agentId: "agent-123",
  intent: "Grow treasury by 5% using neutral strategies",
  targetAsset: "USDC",
  targetAmount: "1050", // 5% of $1000
  maxDuration: 3600, // 1 hour
  toleranceLevel: "low" // "low" | "medium" | "high"
}

Response:
{
  missionId: "mission-456",
  status: "pending",
  estimatedSteps: 4,
  estimatedCost: "0.15", // USD
  createdAt: "2026-01-21T10:05:00Z"
}
```

**GET `/api/missions/{missionId}`**
```typescript
Response:
{
  missionId: "mission-456",
  agentId: "agent-123",
  intent: "Grow treasury by 5%...",
  status: "executing", // "pending" | "executing" | "completed" | "failed"
  progress: {
    currentStep: 2,
    totalSteps: 4,
    completion: 50
  },
  timeline: [
    {
      step: 1,
      description: "Fetch CDC market data",
      status: "completed",
      duration: "234ms",
      cost: "$0.01"
    },
    {
      step: 2,
      description: "Swap USDC→CRO on VVS",
      status: "in-progress",
      duration: "1.2s",
      cost: "$0.04"
    }
  ],
  totalCostSoFar: "$0.05",
  estimatedTotalCost: "$0.15"
}
```

**GET `/api/audit-trail`**
```typescript
Query Params:
- agentId: string
- missionId: string (optional)
- startTime: ISO timestamp
- endTime: ISO timestamp
- limit: 100

Response:
{
  logs: [
    {
      timestamp: "2026-01-21T10:05:02.123Z",
      agentId: "agent-123",
      missionId: "mission-456",
      type: "decision",
      message: "Volatility 25% > threshold (20%), executing hedge",
      cost: "$0.02",
      txHash: "0xabcd1234...",
      reasoning: {
        input: { volatility: 25, threshold: 20 },
        output: "EXECUTE_HEDGE",
        confidence: 0.92
      }
    },
    {
      timestamp: "2026-01-21T10:05:03.456Z",
      agentId: "agent-123",
      missionId: "mission-456",
      type: "error",
      message: "Slippage 3.2% > limit (1%)",
      action: "Recalculating route...",
      txHash: null
    }
  ],
  totalCount: 47
}
```

**WS `/api/debug-stream`**
```typescript
Connect with:
{ agentId: "agent-123", missionId: "mission-456" }

Messages (real-time):
{
  type: "ai_thought",
  timestamp: "2026-01-21T10:05:04.789Z",
  agentId: "agent-123",
  thought: "Analyzing VVS liquidity... BTC/USDC pair has sufficient depth",
  confidence: 0.88
}

{
  type: "settlement_step",
  timestamp: "2026-01-21T10:05:05.012Z",
  step: 2,
  action: "SWAP",
  inputAsset: "USDC",
  inputAmount: "100",
  outputAsset: "CRO",
  expectedOutput: "45.5",
  gasCost: "0.04",
  status: "in_progress"
}

{
  type: "tx_confirmed",
  timestamp: "2026-01-21T10:05:06.345Z",
  txHash: "0xef0123456789abcdef...",
  gasUsed: "125000",
  actualCost: "$0.043"
}
```

---

## 📄 Smart Contract Interfaces

### AgentWallet.sol

```solidity
interface IAgentWallet {
  // Initialize agent wallet
  function initializeAgent(
    address owner,
    bytes calldata initialPolicy,
    uint256 initialBalance
  ) external;

  // Add session key for autonomous execution
  function addSessionKey(
    address sessionKey,
    bytes calldata permissions,
    uint256 expirationTime
  ) external;

  // Execute atomic batch of operations
  function executeBatch(
    Operation[] calldata operations,
    bytes calldata signature
  ) external returns (bytes[] memory results);

  struct Operation {
    address target;
    bytes calldata;
    uint256 value;
  }
}
```

### CircuitBreaker.sol

```solidity
interface ICircuitBreaker {
  // Check if operation is within limits
  function checkLimit(
    address agent,
    uint256 amount,
    bytes calldata context
  ) external view returns (bool allowed, uint256 remainingBudget);

  // Record spent amount
  function recordSpend(
    address agent,
    uint256 amount,
    bytes32 missionId
  ) external;

  // Set spending policy
  function setPolicy(
    address agent,
    uint256 perRequestLimit,
    uint256 perMissionLimit,
    uint256 rateLimit
  ) external;
}
```

### BatchSettlement.sol

```solidity
interface IBatchSettlement {
  // Create x402 batch session
  function createBatch(
    bytes32 x402SessionId,
    address[] calldata operationTargets,
    bytes[] calldata operationData
  ) external returns (bytes32 batchId);

  // Execute all operations atomically
  function executeBatch(bytes32 batchId) external returns (bool);

  // Query batch status
  function getBatchStatus(bytes32 batchId) external view 
    returns (
      uint8 status, // 0=pending, 1=executing, 2=completed, 3=failed
      uint256 gasCostSaved,
      uint256 totalCost
    );
}
```

---

## 🔄 Data Models

### Agent
```typescript
interface Agent {
  agentId: string;
  name: string;
  owner: Address;
  walletAddress: Address;
  sessionKeyAddress: Address;
  policy: {
    maxSpendPerRequest: BigNumber;
    maxSpendPerMission: BigNumber;
    maxRequestsPerMinute: number;
    allowedDEXs: string[];
    allowedStrategies: string[];
  };
  balance: {
    usdcBalance: BigNumber;
    deployedBalance: BigNumber; // In active missions
  };
  status: "active" | "paused" | "suspended";
  createdAt: Date;
  updatedAt: Date;
}
```

### Mission
```typescript
interface Mission {
  missionId: string;
  agentId: string;
  intent: string; // Natural language intent
  executionPlan: Step[];
  status: "pending" | "executing" | "completed" | "failed" | "recovered";
  results: {
    initialBalance: BigNumber;
    finalBalance: BigNumber;
    gain: BigNumber;
    totalCost: BigNumber;
    success: boolean;
    recoveryCount: number;
  };
  timeline: {
    createdAt: Date;
    startedAt: Date;
    completedAt: Date;
    duration: number; // milliseconds
  };
  auditTrail: AuditEntry[];
}

interface Step {
  stepId: number;
  description: string;
  operation: Operation;
  cost: BigNumber;
  status: "pending" | "executing" | "completed" | "failed";
  result: any;
  error?: string;
}
```

### Settlement
```typescript
interface Settlement {
  settlementId: string;
  x402SessionId: string;
  missionId: string;
  operations: SettlementOperation[];
  status: "pending" | "confirmed" | "failed";
  gasSavings: {
    batchedGasCost: BigNumber;
    estimatedIndividualGasCost: BigNumber;
    savingsPercent: number; // 40 for 40%
  };
  txHash: string;
  blockNumber: number;
  timestamp: Date;
}

interface SettlementOperation {
  operationId: number;
  type: "swap" | "perp" | "data_fetch" | "payment";
  input: any;
  output: any;
  cost: BigNumber;
}
```

### AuditEntry
```typescript
interface AuditEntry {
  timestamp: Date;
  entryId: string;
  type: "decision" | "error" | "recovery" | "settlement" | "cost";
  agentId: string;
  missionId: string;
  
  // AI decision logging
  aiThought?: string;
  aiConfidence?: number;
  aiReasoning?: {
    input: any;
    output: string;
  };

  // Cost tracking
  action?: string;
  cost?: BigNumber;
  txHash?: string;

  // Error & recovery
  error?: string;
  recoveryAction?: string;
  recoverySuccess?: boolean;
}
```

---

## 🔐 Security Model

### Permission Levels
```
Level 1: User (Mission creation only)
Level 2: Agent (Autonomous execution within policies)
Level 3: Session Key (Temporary elevated permissions)
Level 4: Admin (Emergency overrides, policy updates)
```

### Circuit Breaker Enforcement
```
Per Request:  Max $50
Per Mission:  Max $500
Per Minute:   Max 10 requests
Rate Limit:   Exponential backoff on failures
```

### Signature Requirements
```
For policy changes:  Owner signature required
For batch execution: Session key OR owner signature
For emergency pause: Admin signature
```

---

## 📊 Metrics & Monitoring

### Key Performance Indicators
```
gas_saved_percent          → Target: 40%
mission_success_rate       → Target: 95%
mission_completion_time    → Target: <30s (batch to settlement)
circuit_breaker_blocks     → Target: 0 unintended overspends
audit_trail_completeness   → Target: 100%
recovery_success_rate      → Target: 80% (when attempted)
```

### Logging Strategy
```
INFO:   Mission start/completion, policy enforcement
WARN:   Slippage detected, retry attempted, near limit
ERROR:  Mission failure, circuit breaker trigger, tx revert
DEBUG:  Every AI thought, route calculation, cost breakdown
```

---

## 🚀 Deployment Architecture

### Local Development
```
Services:
├─ PostgreSQL (localhost:5432)
├─ Redis (localhost:6379)
├─ Backend API (localhost:3001)
├─ MCP Server (localhost:3002)
├─ Frontend (localhost:5173)
└─ Hardhat Node (localhost:8545)
```

### Production (Cronos testnet)
```
Services:
├─ RDS PostgreSQL
├─ ElastiCache Redis
├─ ECS Fargate (Backend)
├─ ECS Fargate (MCP Server)
├─ CloudFront (Frontend)
├─ Smart Contracts (Cronos zkEVM)
└─ CloudWatch (Monitoring)
```

### GitHub Actions CI/CD
```
On push to main:
1. Lint + Format check
2. Smart contract tests + gas optimization
3. Backend unit tests
4. Integration tests
5. Build Docker images
6. Deploy to staging
7. E2E tests on staging
8. Deploy to production
```

---

## 🧪 Testing Strategy

### Unit Tests (60% coverage target)
- Each smart contract function
- Parser logic (intent → execution plan)
- Route calculation algorithms
- Circuit breaker enforcement

### Integration Tests (30% coverage target)
- Agent creation → policy enforcement
- Mission execution → settlement
- MCP server → agent communication
- Error detection → recovery flow

### E2E Tests (10% coverage target)
- Complete mission lifecycle (create → execute → audit)
- Self-healing recovery scenario
- Multi-agent concurrent missions
- Gas savings measurement

### Performance Tests
- Load test: 10 concurrent agents, 100 missions/minute
- Latency: API response <100ms (p95)
- Settlement: Batch execution <30s
- MCP Server: Price feed latency <500ms

---

## 📖 Documentation Deliverables

1. **ARCHITECTURE.md** - System design + data flow
2. **QUICK_START.md** - Dev environment setup, first agent
3. **API.md** - Complete REST API reference
4. **SMART_CONTRACTS.md** - Contract ABIs, deployment
5. **MCP_INTEGRATION.md** - MCP server setup + tools
6. **SAFETY_MODEL.md** - Circuit breaker + policy enforcement
7. **DEBUGGING.md** - Black Box debugger usage + audit trail
8. **DEPLOYMENT.md** - Production deployment + monitoring

---

## 🎯 Success Criteria

✅ **Functional Requirements:**
- Agent can execute missions autonomously
- Batch settlement reduces gas by 40%+
- Circuit breaker enforces all limits
- Self-healing recovers from ≥3 failure types
- Audit trail is 100% complete

✅ **Non-Functional Requirements:**
- API p95 latency: <100ms
- Mission completion time: <30s
- System uptime: 99.9%
- Code coverage: >80%
- Deployment time: <10 minutes

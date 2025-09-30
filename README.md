# Service Bus Premium Messaging .NET Performance Test

[The sample](./ThroughputTest) in this repo can be used to help benchmark Service Bus Premium Messaging throughput, 
and can be used to study performance best practices. 

A latency-focused sample will be published in the near future, as measuring latency and throughput limits at the same time is not possible. Send operations are generally somewhat less expensive than receives, and therefore 10000 sends in a fast-as-possible burst create a prompt traffic jam in the queue that a receiver simply can’t keep up with. That means the end-to-end passthrough latency for each message goes up when the throughput limits are pushed. Optimal latency, meaning a minimal passthrough time of messages through the system, is not achievable under maximum throughput pressure.

## Docker Usage

### Building the Image

```bash
docker build -t sb-dotnet-test .
```

### Authentication Options

#### Option 1: Azure CLI Authentication (Recommended for Development)

First, authenticate with Azure CLI on your host machine:

```bash
# Login to Azure
az login

# (Optional) Set your subscription if you have multiple
az account set --subscription "your-subscription-id"
```

Then run the container with Azure CLI credentials mounted:

```bash
# Mount Azure CLI credentials from host (rw required for token refresh)
docker run --rm -it \
  -v ~/.azure:/root/.azure:rw \
  sb-dotnet-test \
  dotnet ServiceBusThroughputTest.dll \
  --namespace "your-servicebus-namespace.servicebus.windows.net" \
  --entity-path "your-queue-or-topic" \
  --sender-count 10 \
  --receiver-count 10 \
  --frequency-metrics 10
```

#### Option 2: Connection String Authentication

```bash
docker run --rm -it \
  sb-dotnet-test \
  dotnet ServiceBusThroughputTest.dll \
  --connection-string "Endpoint=sb://your-namespace.servicebus.windows.net/;SharedAccessKeyName=...;SharedAccessKey=..." \
  --entity-path "your-queue-or-topic" \
  --sender-count 10 \
  --receiver-count 10 \
  --frequency-metrics 10
```

#### Option 3: Managed Identity (For Azure Container Instances or AKS)

When running in Azure with managed identity enabled:

```bash
docker run --rm -it \
  sb-dotnet-test \
  dotnet ServiceBusThroughputTest.dll \
  --namespace "your-servicebus-namespace.servicebus.windows.net" \
  --entity-path "your-queue-or-topic" \
  --sender-count 10 \
  --receiver-count 10 \
  --frequency-metrics 10
```

### Command Line Parameters

#### Required Parameters
- `--entity-path` (`-S`): Queue or Topic name. For Topic/Subscription, use format: `topic:subscription`

#### Authentication Parameters (choose one)
- `--connection-string` (`-C`): Service Bus connection string
- `--namespace` (`-N`): Service Bus namespace (e.g., 'myservicebus.servicebus.windows.net' - uses Azure Identity)

#### Performance Parameters
- `--sender-count` (`-s`): Number of concurrent senders (default: 1)
- `--receiver-count` (`-r`): Number of concurrent receivers (default: 5)
- `--frequency-metrics` (`-f`): Frequency of metrics display in seconds (default: 10)
- `--send-batch-size` (`-t`): Number of messages per send batch (default: 1)
- `--receive-batch-size` (`-v`): Max messages per receive batch (default: 1)
- `--payload-size-bytes` (`-b`): Message size in bytes (default: 1024)
- `--prefetch-count` (`-p`): Prefetch count (default: 100)
- `--inflight-sends` (`-i`): Max concurrent in-flight send operations (default: 1)
- `--inflight-receives` (`-j`): Max concurrent in-flight receive operations per receiver (default: 1)
- `--receive-mode` (`-m`): Receive mode - true for PeekLock (default), false for ReceiveAndDelete
- `--send-callIntervalMs` (`-d`): Delay between sends in milliseconds (default: 1000)
- `--receive-callIntervalMs` (`-e`): Receive timeout in milliseconds (default: 5000)

### Example Performance Test Scenarios

#### Basic Test
```bash
# Simple test with minimal parameters
docker run --rm -it \
  -v ~/.azure:/root/.azure:rw \
  sb-dotnet-test \
  dotnet ServiceBusThroughputTest.dll \
  -N "your-servicebus-namespace.servicebus.windows.net" \
  -S "testqueue"
```

#### Comprehensive Performance Test
```bash
# Full-featured performance test with optimized parameters
docker run --rm -it \
  -v ~/.azure:/root/.azure:rw \
  sb-dotnet-test \
  dotnet ServiceBusThroughputTest.dll \
  --namespace "your-servicebus-namespace.servicebus.windows.net" \
  --entity-path "testqueue" \
  --sender-count 15 \
  --receiver-count 15 \
  --send-batch-size 50 \
  --receive-batch-size 50 \
  --payload-size-bytes 2048 \
  --inflight-sends 5 \
  --inflight-receives 5 \
  --prefetch-count 200 \
  --frequency-metrics 5 \
  --send-callIntervalMs 100 \
  --receive-callIntervalMs 2000 \
  --receive-mode true
```

#### High Throughput Test
```bash
docker run --rm -it \
  -v ~/.azure:/root/.azure:rw \
  sb-dotnet-test \
  dotnet ServiceBusThroughputTest.dll \
  --namespace "your-servicebus-namespace.servicebus.windows.net" \
  --entity-path "high-throughput-queue" \
  --sender-count 20 \
  --receiver-count 20 \
  --frequency-metrics 5 \
  --send-batch-size 100 \
  --receive-batch-size 100 \
  --payload-size-bytes 512 \
  --inflight-sends 10 \
  --inflight-receives 10
```

#### Low Latency Test
```bash
docker run --rm -it \
  -v ~/.azure:/root/.azure:rw \
  sb-dotnet-test \
  dotnet ServiceBusThroughputTest.dll \
  --namespace "your-servicebus-namespace.servicebus.windows.net" \
  --entity-path "low-latency-queue" \
  --sender-count 1 \
  --receiver-count 1 \
  --frequency-metrics 1 \
  --send-batch-size 1 \
  --receive-batch-size 1 \
  --payload-size-bytes 256 \
  --send-callIntervalMs 0 \
  --receive-callIntervalMs 1000
```

#### Topic/Subscription Test
```bash
docker run --rm -it \
  -v ~/.azure:/root/.azure:rw \
  sb-dotnet-test \
  dotnet ServiceBusThroughputTest.dll \
  --namespace "your-servicebus-namespace.servicebus.windows.net" \
  --entity-path "test-topic:test-subscription" \
  --sender-count 5 \
  --receiver-count 5 \
  --frequency-metrics 10
```

### Interactive Mode

To get an interactive shell in the container (useful for debugging):

```bash
# With Azure CLI credentials (rw required for token refresh)
docker run --rm -it \
  -v ~/.azure:/root/.azure:rw \
  --entrypoint /bin/bash \
  sb-dotnet-test

# Inside the container, you can:
# - Run: az account show
# - Run: dotnet ServiceBusThroughputTest.dll --help
# - Test connectivity: az servicebus namespace show --name your-namespace --resource-group your-rg
```

### Azure CLI Commands for Service Bus Management

From within the container, you can use Azure CLI to manage Service Bus resources (if you have the rights)

```bash
# List namespaces
az servicebus namespace list

# Create a queue
az servicebus queue create \
  --name test-queue \
  --namespace-name your-namespace \
  --resource-group your-resource-group

# Show queue details
az servicebus queue show \
  --name test-queue \
  --namespace-name your-namespace \
  --resource-group your-resource-group
```

### Development Notes

- The application uses Azure.Identity's DefaultAzureCredential for authentication (check order of attemps in the docs)
- Connection string authentication bypasses Azure Identity
- The benchmark will run until you press Enter, displaying throughput metrics at the specified frequencyice Bus Premium Messaging .NET Performance Test


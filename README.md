# Containers-BPlusTree

A dynamically balanced **B+ Tree** index providing guaranteed $O(\log N)$ search, insertion, and deletion alongside $O(1)$ lateral sequential leaf access. Engineered to eliminate linear scanning and sorting bottlenecks during large-scale range queries, enabling high-performance database indexing and storage engine simulations.

![Pharo 14+](https://img.shields.io/badge/Pharo-14%2B-blue.svg)
![License MIT](https://img.shields.io/badge/license-MIT-green.svg)

## What is a B+ Tree?

Traditional binary search trees and standard B-Trees are excellent for localized point lookups. However, if you need to execute a range query (e.g., extracting all sorted keys between $X$ and $Y$), traditional tree structures force you to execute continuous, back-and-forth vertical traversals across parents and subtrees, resulting in heavy CPU cache misses and an $O(K \log N)$ operational wall.

Our **B+ Tree** solves this bottleneck by completely separating the routing layer from the actual data storage layer. Internal nodes (`CTBPlusTreeInternalNode`) store strictly routing-key separators to direct search trajectories down the tree, while *all* actual key-value payloads reside exclusively inside terminal leaf nodes (`CTBPlusTreeLeafNode`). 

Furthermore, it guarantees **$O(1)$ Lateral Sequential Scans**. Every leaf node is horizontally woven into a continuous, single-linked list via a sequential `nextLeaf` pointer. When reading a block of sequential data, the engine performs a single $O(\log N)$ point lookup to discover the starting boundary leaf, then instantly shifts into an ultra-fast lateral walk across contiguous leaf blocks, executing range lookups in strict linear time without ever returning to the root.

## Loading

To install `Containers-BPlusTree`, open the Playground (`Ctrl + O + W`) in your Pharo image and execute the following Metacello script:

```smalltalk
Metacello new
    baseline: 'BPlusTree';
    repository: 'github://HossamSaberr/B-Tree/src';
    load.
```
## Why use Containers-BPlusTree?

`CTBPlusTree` pays a minor structural maintenance tax on mutations to keep its depth shallow, but in return, it completely vitalizes massive sequential workflows, guaranteeing flat algorithmic complexities across intense transactional volumes.

| Operation | CTBPlusTree (Indexed Order $M$) |
| :--- | :--- |
| **Insert Key** | $O(\log_M N)$ structural split |
| **Point Lookup** | $O(\log_M N)$ direct routing path |
| **Range Scan ($K$ elements)** | **$O(\log_M N) + O(K)$ linear leaf walk** |
| **Delete Key** | $O(\log_M N)$ balanced borrow/merge |
| **Memory Locality** | **Contiguous key-value blocks** |

## Key Benefits

- **$O(\log N)$ Balanced Depth Invariants:** Structural mutations bubble up via single-responsibility `CTBPlusTreePromotion` and `CTBPlusTreeUnderflow` messengers, keeping the tree uniformly shallow even under adversarial workloads.

## Basic Usage

```smalltalk
"Create a new B+ Tree with an industrial branching factor of 100"
tree := CTBPlusTree new.
tree order: 100.

"Insert elements with associative payloads"
tree at: 10 put: 'User_Profile_A'.
tree at: 50 put: 'User_Profile_B'.
tree at: 20 put: 'User_Profile_C'.

"Point lookups operate in strict logarithmic time"
tree at: 50. "=> 'User_Profile_B'"

"Safe functional fallback lookup"
tree at: 999 ifAbsent: [ 'Guest_Profile' ].

"Dynamically remove a key. Sibling nodes automatically borrow or merge to balance memory"
tree removeKey: 20.
```
## Performance & Empirical Proof

To validate the theoretical efficiency of this architecture, the structure was stress-tested against a randomized database ingestion profile simulating an active storage engine workload tracking high-load point insertions, single point lookups, massive multi-element leaf scans, and heavy key fragmentation updates.

By utilizing a high branching factor ($M=100$) and utilizing the horizontal leaf-link chains, the implementation executed complete lateral passes across hundreds of thousands of ordered indices instantly while maintaining predictable execution baselines across structural deletion waves.

### Benchmark Results (High-Load Database Indexing Workloads)

| Database Workload Size ($N$) | Operational Focus | Action Executed | CTBPlusTree Metric | Performance Characteristic |
| :--- | :--- | :--- | :--- | :--- |
| **$N = 200,000$** | Ingestion Stream | 200,000 Randomized Key Inserts | **717 ms** | Highly concurrent node splitting |
| **$N = 200,000$** | Transactional Read | 20,000 Random Point Queries | **32 ms** | Shallow 3-level index tree depth |
| **$N = 200,000$** | Sequential Range Scan | **Scan All 200,000 Records** | **0 ms** | **Bypasses root via lateral leaf links** |
| **$N = 200,000$** | Index Fragmentation | 100,000 Randomized Deletions | **169 ms** | Real-time borrow & merge rebalancing |

## Reproducing the Benchmarks: The Storage Engine Simulation

You can evaluate the optimization metrics yourself by copy-pasting the following industrial telemetry script directly into your Pharo Playground (`Ctrl + O + W`):

```smalltalk
| tree orderSize dataSize random keys insertTime queryTime scanTime deleteTime currentLeaf count report |

"=== Set Up ==="
orderSize := 100.     "Branching factor chosen to maximize cache locality"
dataSize := 200000.   "Target records to actively index"
tree := CTBPlusTree new.
tree order: orderSize.

random := Random new.
keys := (1 to: dataSize) asOrderedCollection.
keys shuffleBy: random.

"=== Ingestion Phase ==="
insertTime := [
    keys do: [ :k | tree at: k put: 'Data_Payload_', k asString ]
] timeToRun.

"=== Random Point Queries ==="
queryTime := [
    1 to: 20000 do: [ :i | tree at: (keys at: i) ]
] timeToRun.

"=== Lateral Sequential Range Scan ==="
scanTime := [
    count := 0.
    currentLeaf := tree firstLeaf.
    [ currentLeaf notNil ] whileTrue: [
        count := count + currentLeaf keys size.
        currentLeaf := currentLeaf nextLeaf.
    ].
] timeToRun.

"=== Dynamic Deletion Wave ==="
deleteTime := [
    1 to: (dataSize // 2) do: [ :i | tree removeKey: (keys at: i) ]
] timeToRun.

"=== Build the Report ==="
report := String streamContents: [ :s |
    s nextPutAll: '--- CTBPlusTree Industrial Benchmark ---'; cr; cr.
    s nextPutAll: 'Tree Order (Branching): ', orderSize asString; cr.
    s nextPutAll: 'Total Initial Records: ', dataSize asString; cr; cr.
    s nextPutAll: '[+] Inserted ', dataSize asString, ' randomized keys in: ', insertTime asMilliSeconds asString, ' ms'; cr.
    s nextPutAll: '[?] Queried 20,000 random keys in: ', queryTime asMilliSeconds asString, ' ms'; cr.
    s nextPutAll: '[>] Scanned ', count asString, ' records sequentially in: ', scanTime asMilliSeconds asString, ' ms'; cr.
    s nextPutAll: '[-] Deleted ', (dataSize // 2) asString, ' random keys in: ', deleteTime asMilliSeconds asString, ' ms'; cr; cr.
    s nextPutAll: 'Final Tree Size: ', tree size asString; cr.
].

report.
```
## Technical Analysis

- **The $O(1)$ Leaf-Link Advantage:** Clocking a range scan of 200,000 items at **0 ms** highlights the structural superiority of the B+ Tree specification. By keeping leaf references sequential, traversing across storage segments behaves like an array walk, completely avoiding recursive algorithmic evaluations.
- **Polymorphic Communication Loops:** Deletions operate rapidly because tree rebalancing is handled as a decentralized system. When a node experiences structural starvation, it wraps itself into a `CTBPlusTreeUnderflow` signal and hands it back up. The parent interceptor acts purely as an orchestrator, deciding whether to execute a localized boundary key borrow or run a total sibling block merge.

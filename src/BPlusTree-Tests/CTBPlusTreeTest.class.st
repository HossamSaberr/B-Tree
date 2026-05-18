Class {
	#name : 'CTBPlusTreeTest',
	#superclass : 'TestCase',
	#instVars : [
		'tree'
	],
	#category : 'BPlusTree-Tests',
	#package : 'BPlusTree-Tests'
}

{ #category : 'running' }
CTBPlusTreeTest >> setUp [
    super setUp.
    tree := CTBPlusTree new.
    tree order: 4. "Defaulting to a small order to force early splits"
]

{ #category : 'tests' }
CTBPlusTreeTest >> testAlternatingBoundsStress [
    | left right |
    left := 1.
    right := 1000.
    
    [ left <= right ] whileTrue: [
        tree at: left put: left.
        left ~= right ifTrue: [ tree at: right put: right ].
        left := left + 1.
        right := right - 1.
    ].
    
    self assert: tree size equals: 1000.
    self assert: (tree at: 500) equals: 500.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testAlternatingInsertions [
    "testing complex routing with unpredictable insertion indexes"
    | keys |
    keys := #(10 90 20 80 30 70 40 60 50).
    keys do: [ :k | tree at: k put: k ].
    self assert: tree size equals: 9.
    keys do: [ :k | self assert: (tree at: k) equals: k ].
]

{ #category : 'tests' }
CTBPlusTreeTest >> testBasicDeletion [
    tree at: 10 put: 'A'.
    tree at: 20 put: 'B'.
    tree at: 30 put: 'C'.
    
    tree removeKey: 20.
    
    self assert: tree size equals: 2.
    self assert: (tree at: 10) equals: 'A'.
    self assert: (tree at: 30) equals: 'C'.
    self should: [ tree at: 20 ] raise: Error.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testCustomOrderSplits [
    tree order: 3. 
    1 to: 50 do: [ :i | tree at: i put: i ].
    self assert: tree size equals: 50.
    1 to: 50 do: [ :i | self assert: (tree at: i) equals: i ].
]

{ #category : 'tests' }
CTBPlusTreeTest >> testDescendingInsertions [
    "forces insertions at index 1, testing the findFirst: = 0 edge cases"
    20 to: 1 by: -1 do: [ :i | tree at: i put: i ].
    self assert: tree size equals: 20.
    1 to: 20 do: [ :i | self assert: (tree at: i) equals: i ].
]

{ #category : 'tests' }
CTBPlusTreeTest >> testDuplicateKeyStress [
    "spam the exact same key to ensure the tree doesnt inflate or split unnecessarily"
    1 to: 5000 do: [ :i | tree at: 42 put: 'Value', i asString ].
    
    self assert: tree size equals: 1.
    self assert: (tree at: 42) equals: 'Value5000'.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testEmptyTree [
    self assert: tree size equals: 0.
    self should: [ tree at: 1 ] raise: Error.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testInsertUntilFirstSplit [
    "order 4 means it splits when inserting the 4th element"
    1 to: 4 do: [ :i | tree at: i put: i asString ].
    self assert: tree size equals: 4.
    1 to: 4 do: [ :i | self assert: (tree at: i) equals: i asString ].
]

{ #category : 'tests' }
CTBPlusTreeTest >> testInsertUntilRootSplits [
    "forces internal nodes to split and bubble a new root up"
    1 to: 20 do: [ :i | tree at: i put: i ].
    self assert: tree size equals: 20.
    1 to: 20 do: [ :i | self assert: (tree at: i) equals: i ].
]

{ #category : 'tests' }
CTBPlusTreeTest >> testInterleavedInsertions [
    "insert all odds, then all evens"
    1 to: 1000 by: 2 do: [ :i | tree at: i put: i ].
    2 to: 1000 by: 2 do: [ :i | tree at: i put: i ].
    
    self assert: tree size equals: 1000.
    1 to: 1000 do: [ :i | self assert: (tree at: i) equals: i ].
]

{ #category : 'tests' }
CTBPlusTreeTest >> testLargeRandomizedStress [
    | randomizer keys |
    randomizer := Random new.
    keys := (1 to: 10000) asOrderedCollection.
    keys shuffleBy: randomizer.
    
    keys do: [ :k | tree at: k put: k * 2 ]. "Value is double the key"
    
    self assert: tree size equals: 10000.
    
    "check a few random ones"
    self assert: (tree at: 42) equals: 84.
    self assert: (tree at: 999) equals: 1998.
    self assert: (tree at: 10000) equals: 20000.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testLargeReverseStress [
    10000 to: 1 by: -1 do: [ :i | tree at: i put: i ].
    self assert: tree size equals: 10000.
    self assert: (tree at: 1) equals: 1.
    self assert: (tree at: 5000) equals: 5000.
    self assert: (tree at: 10000) equals: 10000.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testLargeSequentialStress [
    1 to: 10000 do: [ :i | tree at: i put: i ].
    self assert: tree size equals: 10000.
    self assert: (tree at: 1) equals: 1.
    self assert: (tree at: 5000) equals: 5000.
    self assert: (tree at: 10000) equals: 10000.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testLeafBorrowFromRight [
    "insert 1..5, Splits into Left [1, 2] and Right [3, 4, 5]"
    1 to: 5 do: [ :i | tree at: i put: i ].
    
    "delete 1, Left drops to [2], Right has 3, so it LENDS the 3"
    "left becomes [2, 3], Right becomes [4, 5], Root key updates"
    tree removeKey: 1.
    
    self assert: tree size equals: 4.
    self assert: (tree at: 2) equals: 2.
    self assert: (tree at: 5) equals: 5.
    self should: [ tree at: 1 ] raise: Error.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testLeafMergeAndRootCollapse [
    "insert 1..4, Splits into Left [1, 2] and Right [3, 4] with Root having 1 key"
    1 to: 4 do: [ :i | tree at: i put: i ].
    
    "delete 1, Left drops to [2], Right only has [3, 4], so it CANNOT lend"
    "they MERGE into [2, 3, 4], The Root loses its key and collapses"
    tree removeKey: 1.
    
    self assert: tree size equals: 3.
    self assert: (tree at: 2) equals: 2.
    self assert: (tree at: 3) equals: 3.
    self assert: (tree at: 4) equals: 4.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testMassiveRandomizedDeletionStress [
    | randomizer keys keysToDelete keysToKeep |
    randomizer := Random new.
    keys := (1 to: 10000) asOrderedCollection.
    keys shuffleBy: randomizer.
    
    "Insert all 10000"
    keys do: [ :k | tree at: k put: k ].
    
    "Split into two groups"
    keysToDelete := keys copyFrom: 1 to: 5000.
    keysToKeep := keys copyFrom: 5001 to: 10000.
    
    "Destroy half the tree randomly"
    keysToDelete do: [ :k | tree removeKey: k ].
    
    self assert: tree size equals: 5000.
    
    "Check the surviving half survived"
    keysToKeep do: [ :k | 
        self assert: (tree at: k) equals: k 
    ].
    
    "Check the deleted half is actually gone"
    keysToDelete do: [ :k | 
        self should: [ tree at: k ] raise: Error 
    ].
]

{ #category : 'tests' }
CTBPlusTreeTest >> testMissingKeyIfAbsent [
    | result |
    result := tree at: 99 ifAbsent: [ 'NotFound' ].
    self assert: result equals: 'NotFound'.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testMissingKeyThrowsError [
    tree at: 1 put: 'A'.
    self should: [ tree at: 99 ] raise: Error.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testSequentialLeafLinksAscending [
    | currentLeaf count |
    1 to: 50 do: [ :i | tree at: i put: i ].
    
    currentLeaf := tree firstLeaf.
    count := 0.
    [ currentLeaf notNil ] whileTrue: [
        count := count + currentLeaf keys size.
        currentLeaf := currentLeaf nextLeaf.
    ].
    
    self assert: count equals: 50.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testSequentialLeafLinksDescending [
    | currentLeaf count |
    50 to: 1 by: -1 do: [ :i | tree at: i put: i ].
    
    currentLeaf := tree firstLeaf.
    count := 0.
    [ currentLeaf notNil ] whileTrue: [
        count := count + currentLeaf keys size.
        currentLeaf := currentLeaf nextLeaf.
    ].
    
    self assert: count equals: 50.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testSequentialLinksAfterMassiveDeletions [
    | currentLeaf count |
    "Build a large tree"
    1 to: 1000 do: [ :i | tree at: i put: i ].
    
    "Punch holes throughout the entire tree to force dozens of merges"
    1 to: 1000 by: 2 do: [ :i | tree removeKey: i ].
    
    self assert: tree size equals: 500.
    
    "Traverse the surviving linked list to ensure no pointers point to dead memory"
    currentLeaf := tree firstLeaf.
    count := 0.
    [ currentLeaf notNil ] whileTrue: [
        count := count + currentLeaf keys size.
        currentLeaf := currentLeaf nextLeaf.
    ].
    
    self assert: count equals: 500.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testSequentialUpdateStress [
    "Build"
    1 to: 2000 do: [ :i | tree at: i put: 'Initial' ].
    self assert: tree size equals: 2000.
    
    "Rewrite"
    1 to: 2000 do: [ :i | tree at: i put: 'Updated' ].
    self assert: tree size equals: 2000. "Size MUST remain exactly the same"
    
    "Check"
    self assert: (tree at: 1000) equals: 'Updated'.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testSingleInsertion [
    tree at: 10 put: 'A'.
    self assert: tree size equals: 1.
    self assert: (tree at: 10) equals: 'A'.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testUpdateExistingKey [
    tree at: 10 put: 'A'.
    tree at: 10 put: 'B'.
    self assert: tree size equals: 1.
    self assert: (tree at: 10) equals: 'B'.
]

{ #category : 'tests' }
CTBPlusTreeTest >> testWideTreeStress [
    | largeTree |
    largeTree := CTBPlusTree new.
    largeTree order: 100. "Massive branching factor"
    
    1 to: 5000 do: [ :i | largeTree at: i put: i ].
    
    self assert: largeTree size equals: 5000.
    self assert: (largeTree at: 2500) equals: 2500.
]

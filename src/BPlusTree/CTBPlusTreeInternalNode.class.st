Class {
	#name : 'CTBPlusTreeInternalNode',
	#superclass : 'CTBPlusTreeNode',
	#instVars : [
		'children'
	],
	#category : 'BPlusTree',
	#package : 'BPlusTree'
}

{ #category : 'instance creation' }
CTBPlusTreeInternalNode class >> keys: aKeyCollection children: aChildCollection [
    ^ self new setKeys: aKeyCollection children: aChildCollection
]

{ #category : 'private' }
CTBPlusTreeInternalNode >> absorbSplitKey: aKey rightChild: rightNode order: maxOrder [
    | insertIndex |
    insertIndex := keys findFirst: [ :k | aKey < k ].
        
    insertIndex = 0 ifTrue: [
        keys addLast: aKey.
        children addLast: rightNode.
    ] ifFalse: [
        keys add: aKey beforeIndex: insertIndex.
        children add: rightNode beforeIndex: insertIndex + 1.
    ].
    
    ^ keys size < maxOrder 
        ifTrue: [ self ]
        ifFalse: [ self splitInternal ]
]

{ #category : 'private' }
CTBPlusTreeInternalNode >> addFirstChild: aNode [
    children add: aNode.
]

{ #category : 'private' }
CTBPlusTreeInternalNode >> borrowFromLeftSibling: leftSibling parent: parentNode keyIndex: parentKeyIndex [
    | borrowedKey borrowedChild |
    borrowedChild := leftSibling children removeLast.
    borrowedKey := leftSibling keys removeLast.
    
    children addFirst: borrowedChild.
    
    "Pull the parent old key down to me, push the left sibling key up to the parent"
    keys addFirst: (parentNode keys at: parentKeyIndex).
    parentNode keys at: parentKeyIndex put: borrowedKey.
]

{ #category : 'private' }
CTBPlusTreeInternalNode >> borrowFromRightSibling: rightSibling parent: parentNode keyIndex: parentKeyIndex [
    | borrowedKey borrowedChild |
    borrowedChild := rightSibling children removeFirst.
    borrowedKey := rightSibling keys removeFirst.
    
    children addLast: borrowedChild.
    
    "Pull the parent old key down to me, push the right sibling key up to the parent"
    keys addLast: (parentNode keys at: parentKeyIndex).
    parentNode keys at: parentKeyIndex put: borrowedKey.
]

{ #category : 'private' }
CTBPlusTreeInternalNode >> childForKey: aKey [
    | index |
    index := keys findFirst: [ :k | aKey < k ].
    index = 0 ifTrue: [ ^ children last ].
    ^ children at: index.
]

{ #category : 'accessing' }
CTBPlusTreeInternalNode >> children [
    ^ children
]

{ #category : 'accessing' }
CTBPlusTreeInternalNode >> children: anOrderedCollection [
    children := anOrderedCollection
]

{ #category : 'removing' }
CTBPlusTreeInternalNode >> handleUnderflowAt: childIndex order: maxOrder [
    | targetChild minSize leftSibling rightSibling |
    targetChild := children at: childIndex.
    minSize := maxOrder // 2.
    
    "Can we BORROW from the LEFT?"
    childIndex > 1 ifTrue: [
        leftSibling := children at: childIndex - 1.
        leftSibling keys size > minSize ifTrue: [
            targetChild borrowFromLeftSibling: leftSibling parent: self keyIndex: childIndex - 1.
            ^ self
        ]
    ].
    
    "Can we BORROW from the RIGHT?"
    childIndex < children size ifTrue: [
        rightSibling := children at: childIndex + 1.
        rightSibling keys size > minSize ifTrue: [
            targetChild borrowFromRightSibling: rightSibling parent: self keyIndex: childIndex.
            ^ self
        ]
    ].
    
    "If borrowing fails, we MUST MERGE. Always merge the right node into the left node"
    childIndex > 1 
        ifTrue: [ 
            (children at: childIndex - 1) mergeWithRightSibling: targetChild parent: self keyIndex: childIndex - 1 
        ]
        ifFalse: [ 
            targetChild mergeWithRightSibling: (children at: 2) parent: self keyIndex: 1 
        ].
        
    "Did this merge cause ME to underflow?"
    ^ keys size < minSize 
        ifTrue: [ CTBPlusTreeUnderflow node: self ]
        ifFalse: [ self ]
]

{ #category : 'initialization' }
CTBPlusTreeInternalNode >> initialize [
    super initialize.
    children := OrderedCollection new.
]

{ #category : 'adding' }
CTBPlusTreeInternalNode >> insertKey: aKey value: aValue order: maxOrder [
    | targetChild result |
    targetChild := self childForKey: aKey.
    result := targetChild insertKey: aKey value: aValue order: maxOrder.
    
    ^ result processPromotionIn: self order: maxOrder.
]

{ #category : 'private' }
CTBPlusTreeInternalNode >> insertPromotedKey: aKey child: aNode [
    keys add: aKey.
    children add: aNode.
]

{ #category : 'private' }
CTBPlusTreeInternalNode >> mergeWithRightSibling: rightSibling parent: parentNode keyIndex: parentKeyIndex [
    "Pull the parent's separator key down into me"
    keys addLast: (parentNode keys at: parentKeyIndex).
    
    "Absorb all keys and children from the right sibling"
    keys addAll: rightSibling keys.
    children addAll: rightSibling children.
    
    "Delete the right sibling's routing key and pointer from the parent"
    parentNode keys removeAt: parentKeyIndex.
    parentNode children removeAt: parentKeyIndex + 1.
]

{ #category : 'removing' }
CTBPlusTreeInternalNode >> removeKey: aKey ifAbsent: errorBlock order: maxOrder [
    | childIndex targetChild result |
    
    "Find which child holds the path to this key"
    childIndex := keys findFirst: [ :k | aKey < k ].
    childIndex = 0 ifTrue: [ childIndex := children size ].
    
    targetChild := children at: childIndex.
    
    "Tell the child to remove it"
    result := targetChild removeKey: aKey ifAbsent: errorBlock order: maxOrder.
    
    "Double dispatch, A normal node returns itself, An underflowing node returns the Underflow messenger"
    ^ result processUnderflowIn: self index: childIndex order: maxOrder
]

{ #category : 'accessing' }
CTBPlusTreeInternalNode >> searchKey: aKey ifAbsent: errorBlock [
    ^ (self childForKey: aKey) searchKey: aKey ifAbsent: errorBlock
]

{ #category : 'initialization' }
CTBPlusTreeInternalNode >> setKeys: aKeyCollection children: aChildCollection [
    keys := aKeyCollection.
    children := aChildCollection.
]

{ #category : 'private' }
CTBPlusTreeInternalNode >> splitInternal [
    | middleIndex middleKey newSibling newKeys newChildren |
    middleIndex := (keys size // 2) + 1.
    middleKey := keys at: middleIndex.
    
    newKeys := OrderedCollection new.
    newChildren := OrderedCollection new.
    
    middleIndex + 1 to: keys size do: [ :i |
        newKeys addLast: (keys at: i).
    ].
    middleIndex + 1 to: children size do: [ :i |
        newChildren addLast: (children at: i).
    ].
    
    (keys size - middleIndex + 1) timesRepeat: [ keys removeLast ].
    (children size - middleIndex) timesRepeat: [ children removeLast ].
    
    newSibling := self class new.
    newSibling keys: newKeys.
    newSibling children: newChildren.
    
    ^ CTBPlusTreePromotion key: middleKey left: self right: newSibling
]

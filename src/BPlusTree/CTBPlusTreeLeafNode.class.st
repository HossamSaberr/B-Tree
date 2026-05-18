Class {
	#name : 'CTBPlusTreeLeafNode',
	#superclass : 'CTBPlusTreeNode',
	#instVars : [
		'values',
		'nextLeaf'
	],
	#category : 'BPlusTree',
	#package : 'BPlusTree'
}

{ #category : 'instance creation' }
CTBPlusTreeLeafNode class >> keys: aKeyCollection values: aValueCollection nextLeaf: aNode [
    ^ self new setKeys: aKeyCollection values: aValueCollection nextLeaf: aNode
]

{ #category : 'private' }
CTBPlusTreeLeafNode >> borrowFromLeftSibling: leftSibling parent: parentNode keyIndex: parentKeyIndex [
    | borrowedKey borrowedValue |
    borrowedKey := leftSibling keys removeLast.
    borrowedValue := leftSibling values removeLast.
    
    keys addFirst: borrowedKey.
    values addFirst: borrowedValue.
    
    "Update the parent routing key to reflect the new split point"
    parentNode keys at: parentKeyIndex put: keys first.
]

{ #category : 'private' }
CTBPlusTreeLeafNode >> borrowFromRightSibling: rightSibling parent: parentNode keyIndex: parentKeyIndex [
    | borrowedKey borrowedValue |
    borrowedKey := rightSibling keys removeFirst.
    borrowedValue := rightSibling values removeFirst.
    
    keys addLast: borrowedKey.
    values addLast: borrowedValue.
    
    "Update the parent routing key"
    parentNode keys at: parentKeyIndex put: rightSibling keys first.
]

{ #category : 'initialization' }
CTBPlusTreeLeafNode >> initialize [
    super initialize.
    values := OrderedCollection new.
]

{ #category : 'adding' }
CTBPlusTreeLeafNode >> insertKey: aKey value: aValue order: maxOrder [
    | index |
    index := keys findFirst: [ :k | aKey <= k ].
    
    index = 0 ifTrue: [
        "Key is larger than all others, safely append"
        keys addLast: aKey.
        values addLast: aValue.
    ] ifFalse: [
        "Update if exact match"
        (keys at: index) = aKey ifTrue: [ 
            values at: index put: aValue. 
            ^ self 
        ].
        "Otherwise insert at the exact sorted position"
        keys add: aKey beforeIndex: index.
        values add: aValue beforeIndex: index.
    ].
    
    ^ keys size < maxOrder 
        ifTrue: [ self ]
        ifFalse: [ self splitLeaf ]
]

{ #category : 'private' }
CTBPlusTreeLeafNode >> mergeWithRightSibling: rightSibling parent: parentNode keyIndex: parentKeyIndex [
    "Pull all data from the right sibling into me"
    keys addAll: rightSibling keys.
    values addAll: rightSibling values.
    
    "Heal the sequential linked list"
    nextLeaf := rightSibling nextLeaf.
    
    "Delete the right sibling routing key and pointer from the parent"
    parentNode keys removeAt: parentKeyIndex.
    parentNode children removeAt: parentKeyIndex + 1.
]

{ #category : 'accessing' }
CTBPlusTreeLeafNode >> nextLeaf [
    ^ nextLeaf
]

{ #category : 'accessing' }
CTBPlusTreeLeafNode >> nextLeaf: aNode [
    nextLeaf := aNode
]

{ #category : 'removing' }
CTBPlusTreeLeafNode >> removeKey: aKey ifAbsent: errorBlock order: maxOrder [
    | index minSize |
    index := keys indexOf: aKey.
    index = 0 ifTrue: [ ^ errorBlock value ].
    
    "remove the key and value"
    keys removeAt: index.
    values removeAt: index.
    
    "B+ Trees require nodes to be at least half full (except the root)"
    minSize := maxOrder // 2.
    
    ^ keys size < minSize 
        ifTrue: [ CTBPlusTreeUnderflow node: self ]
        ifFalse: [ self ]
]

{ #category : 'accessing' }
CTBPlusTreeLeafNode >> searchKey: aKey ifAbsent: errorBlock [
    | index |
    index := keys indexOf: aKey.
    index = 0 ifTrue: [ ^ errorBlock value ].
    ^ values at: index.
]

{ #category : 'initialization' }
CTBPlusTreeLeafNode >> setKeys: aKeyCollection values: aValueCollection nextLeaf: aNode [
    keys := aKeyCollection.
    values := aValueCollection.
    nextLeaf := aNode.
]

{ #category : 'private' }
CTBPlusTreeLeafNode >> splitLeaf [
    | splitIndex middleKey newSibling newKeys newValues |
    splitIndex := (keys size // 2) + 1.
    
    newKeys := OrderedCollection new.
    newValues := OrderedCollection new.
    
    splitIndex to: keys size do: [ :i |
        newKeys addLast: (keys at: i).
        newValues addLast: (values at: i).
    ].
    
    (keys size - splitIndex + 1) timesRepeat: [
        keys removeLast.
        values removeLast.
    ].
    
    newSibling := self class new.
    newSibling keys: newKeys.
    newSibling values: newValues.
    newSibling nextLeaf: self nextLeaf.
    
    self nextLeaf: newSibling.
    middleKey := newKeys first.
    
    ^ CTBPlusTreePromotion key: middleKey left: self right: newSibling
]

{ #category : 'accessing' }
CTBPlusTreeLeafNode >> values [
    ^ values
]

{ #category : 'accessing' }
CTBPlusTreeLeafNode >> values: anOrderedCollection [
    values := anOrderedCollection
]

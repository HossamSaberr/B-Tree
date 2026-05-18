Class {
	#name : 'CTBPlusTreeNode',
	#superclass : 'Object',
	#instVars : [
		'keys'
	],
	#category : 'BPlusTree',
	#package : 'BPlusTree'
}

{ #category : 'initialization' }
CTBPlusTreeNode >> initialize [
    super initialize.
    keys := OrderedCollection new.
]

{ #category : 'accessing' }
CTBPlusTreeNode >> keys [
    ^ keys
]

{ #category : 'accessing' }
CTBPlusTreeNode >> keys: anOrderedCollection [
    keys := anOrderedCollection
]

{ #category : 'dispatching' }
CTBPlusTreeNode >> processPromotionIn: anInternalNode order: maxOrder [
    "No split happened in me, so my parent doesn't need to split
     Return the parent so it correctly bubbles up its own non split state"
    ^ anInternalNode
]

{ #category : 'dispatching' }
CTBPlusTreeNode >> processRootUpdateFor: aBPlusTree [
    "If I am returned to the tree, no split occurred at the root (I remain the root)"
    aBPlusTree root: self.
]

{ #category : 'dispatching' }
CTBPlusTreeNode >> processUnderflowIn: anInternalNode index: childIndex order: maxOrder [
    "I am not underflowing, Tell the parent everything is fine"
    ^ anInternalNode
]

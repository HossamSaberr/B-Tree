Class {
	#name : 'CTBPlusTreeUnderflow',
	#superclass : 'Object',
	#instVars : [
		'underflowedNode'
	],
	#category : 'BPlusTree',
	#package : 'BPlusTree'
}

{ #category : 'instance creation' }
CTBPlusTreeUnderflow class >> node: aNode [
    ^ self new setNode: aNode
]

{ #category : 'dispatching' }
CTBPlusTreeUnderflow >> processUnderflowIn: anInternalNode index: childIndex order: maxOrder [
    "Tell the parent it has a starving child at this index"
    ^ anInternalNode handleUnderflowAt: childIndex order: maxOrder
]

{ #category : 'initialization' }
CTBPlusTreeUnderflow >> setNode: aNode [
    underflowedNode := aNode.
]

Class {
	#name : 'CTBPlusTreePromotion',
	#superclass : 'Object',
	#instVars : [
		'promotedKey',
		'leftNode',
		'rightNode'
	],
	#category : 'BPlusTree',
	#package : 'BPlusTree'
}

{ #category : 'instance creation' }
CTBPlusTreePromotion class >> key: aKey left: leftNode right: rightNode [
    ^ self new setKey: aKey left: leftNode right: rightNode
]

{ #category : 'dispatching' }
CTBPlusTreePromotion >> processPromotionIn: anInternalNode order: maxOrder [
    "Tell the internal node to absorb the split"
    ^ anInternalNode absorbSplitKey: promotedKey rightChild: rightNode order: maxOrder
]

{ #category : 'dispatching' }
CTBPlusTreePromotion >> processRootUpdateFor: aBPlusTree [
    "A split bubbled all the way up, We need a new root"
    | newRoot |
    newRoot := CTBPlusTreeInternalNode new.
    newRoot addFirstChild: leftNode.
    newRoot insertPromotedKey: promotedKey child: rightNode.
    aBPlusTree root: newRoot.

]

{ #category : 'initialization' }
CTBPlusTreePromotion >> setKey: aKey left: aLeftNode right: aRightNode [
    promotedKey := aKey.
    leftNode := aLeftNode.
    rightNode := aRightNode.
]

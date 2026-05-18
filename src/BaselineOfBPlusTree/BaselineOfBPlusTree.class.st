Class {
	#name : 'BaselineOfBPlusTree',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfBPlusTree',
	#package : 'BaselineOfBPlusTree'
}

{ #category : 'baselines' }
BaselineOfBPlusTree >> baseline: spec [
    <baseline>
    
    spec for: #common do: [ 
        "1. Core Data Structures Package"
        spec package: 'BPlusTree'.
        
        "2. Test Suite Package (Depends on Core)"
        spec package: 'BPlusTree-Tests' with: [ 
            spec requires: #('BPlusTree') 
        ].
        
        "3. Load Groups"
        spec group: 'Core' with: #('BPlusTree').
        spec group: 'Tests' with: #('BPlusTree-Tests').
        spec group: 'default' with: #('Core' 'Tests').
    ]
]

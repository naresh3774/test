1. main.bicepparam (Configuration File)
Line 66-67 - Added new parameter:

// Set to true for a fully private cluster, false for IP-restricted public cluster
```
param enablePrivateCluster = false
```

--------

2. main.bicep (Main Template)
Line 77 - Added parameter declaration:
```
param enablePrivateCluster bool
```

Line 96 - Passed parameter to AKS module:
```
enablePrivateCluster: enablePrivateCluster
```

3. aks.bicep (AKS Module)
Line 5 - Added parameter:
```
param enablePrivateCluster bool
```
Lines 130-135 - Conditional apiServerAccessProfile:
```
apiServerAccessProfile: enablePrivateCluster ? {
  enablePrivateCluster: true
  enablePrivateClusterPublicFQDN: false
} : {
  authorizedIPRanges: authorizedIPRanges
}
```
# Define disk configuration
$disks = @(
    @{ Number = 1; DriveLetter = 'E'; Label = 'Databases';         AllocationUnitSize = 65536 },
    @{ Number = 2; DriveLetter = 'F'; Label = 'Transaction Logs';  AllocationUnitSize = 65536 },
    @{ Number = 3; DriveLetter = 'T'; Label = 'TempDB';            AllocationUnitSize = 65536 },
    @{ Number = 4; DriveLetter = 'Z'; Label = 'Backups';           AllocationUnitSize = 65536 }
)

foreach ($diskInfo in $disks) {
    $diskNumber   = $diskInfo.Number
    $driveLetter  = $diskInfo.DriveLetter
    $label        = $diskInfo.Label
    $unitSize     = $diskInfo.AllocationUnitSize

    Write-Host "Processing Disk $diskNumber..." -ForegroundColor Cyan

    $disk = Get-Disk -Number $diskNumber

    if ($disk.IsOffline) {
        Set-Disk -Number $diskNumber -IsOffline $false
    }

    if ($disk.IsReadOnly) {
        Set-Disk -Number $diskNumber -IsReadOnly $false
    }

    if ($disk.PartitionStyle -eq 'RAW') {
        Initialize-Disk -Number $diskNumber -PartitionStyle GPT
    }

    # Remove existing volumes/partitions if necessary (optional safeguard)
    # Get-Partition -DiskNumber $diskNumber | Remove-Partition -Confirm:$false

    # Create a new partition using all available space
    $partition = New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter

    # Format the partition with FULL format and correct allocation unit size
    Format-Volume -Partition $partition `
                  -FileSystem NTFS `
                  -NewFileSystemLabel $label `
                  -AllocationUnitSize $unitSize `
                  -Full `
                  -Force `
                  -Confirm:$false

    # Set the specified drive letter
    Set-Partition -DriveLetter $partition.DriveLetter -NewDriveLetter $driveLetter

    Write-Host "Disk $diskNumber configured as $driveLetter`: Label='$label', ClusterSize=$unitSize" -ForegroundColor Green
}

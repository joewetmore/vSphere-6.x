#Script to initialze virtual disks after instantiating a VM from the tempate "alv-2022-template v.1.4 (high performance SQL)"

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

    # Create a new partition using all available space
    $partition = New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter

    # Format with NTFS and 64KB allocation unit size
    Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel $label -AllocationUnitSize $unitSize -Confirm:$false

    # Assign specific drive letter
    Set-Partition -DriveLetter $partition.DriveLetter -NewDriveLetter $driveLetter

    Write-Host "Disk $diskNumber configured: $driveLetter`: Label='$label', AllocationUnitSize=$unitSize" -ForegroundColor Green
}


#Section to create subdirectories




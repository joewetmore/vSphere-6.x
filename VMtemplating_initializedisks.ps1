#ver 3

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

    Write-Host "Preparing Disk $diskNumber..." -ForegroundColor Cyan

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

    $partition = New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter

    # Use format.com for a faster format that respects cluster size
    $formatCmd = "format $($partition.DriveLetter): /FS:NTFS /V:`"$label`" /Q /A:$($unitSize) /Y"
    Write-Host "Running: $formatCmd" -ForegroundColor Yellow
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $formatCmd -Wait -NoNewWindow

    Set-Partition -DriveLetter $partition.DriveLetter -NewDriveLetter $driveLetter

    Write-Host "Disk $diskNumber configured: $driveLetter`: Label='$label', ClusterSize=$unitSize" -ForegroundColor Green
}

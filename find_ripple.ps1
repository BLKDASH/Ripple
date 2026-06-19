Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall' | ForEach-Object {
    $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
    if ($props.Publisher -eq 'Ripple') {
        Write-Output "$($_.PSChildName)  $($props.DisplayName)  $($props.DisplayVersion)"
    }
}

# Ścieżka do folderu z kursorami
$sourceFolder = "$(Get-Location)\Cursor"
$targetFolder = "C:\Windows\Cursors\MyCustomCursors"

# Tworzenie folderu docelowego, jeśli nie istnieje
if (-Not (Test-Path $targetFolder)) {
    New-Item -ItemType Directory -Path $targetFolder | Out-Null
}

# Kopiowanie plików kursorów
Write-Host "Kopiowanie kursorów do $targetFolder..."
Copy-Item -Path "$sourceFolder\*" -Destination $targetFolder -Recurse -Force

# Mapowanie kursorów na pliki
$cursorMappings = @{
    "Arrow" = "$targetFolder\1 Normal Select.ani"          # Główny wskaźnik
    "Hand" = "$targetFolder\15 Link Select.ani"            # Wskaźnik linku
    "Help" = "$targetFolder\2 Help Select.ani"             # Wskaźnik pomocy
    "AppStarting" = "$targetFolder\3 Working in Background.ani" # Wskaźnik pracy w tle
    "Wait" = "$targetFolder\4 Busy.ani"                   # Wskaźnik oczekiwania
    "Crosshair" = "$targetFolder\5 Precision Select.ani"   # Wskaźnik precyzyjny
    "IBeam" = "$targetFolder\6 Text Select.ani"            # Wskaźnik tekstu
    "NWPen" = "$targetFolder\7 Handwriting.ani"            # Wskaźnik odręcznego pisania
    "No" = "$targetFolder\8 Unavailable.ani"               # Wskaźnik zakazu
    "SizeNS" = "$targetFolder\9 Vertical Resize.ani"       # Rozciąganie w pionie
    "SizeWE" = "$targetFolder\10 Horizontal Resize.ani"    # Rozciąganie w poziomie
    "SizeNWSE" = "$targetFolder\11 Diagonal Resize 1.ani"  # Rozciąganie po skosie 1
    "SizeNESW" = "$targetFolder\12 Diagonal Resize 2.ani"  # Rozciąganie po skosie 2
    "SizeAll" = "$targetFolder\13 Move.ani"                # Przesuwanie
    "UpArrow" = "$targetFolder\14 Alternate Select.ani"    # Wskaźnik alternatywny
}

# Ustawianie kursorów w rejestrze
Write-Host "Ustawianie kursorów w systemie..."
foreach ($cursor in $cursorMappings.Keys) {
    Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name $cursor -Value $cursorMappings[$cursor]
}

# Tworzenie i zapis schematu
Write-Host "Tworzenie schematu 'UwU'..."
$schemePath = "HKCU:\Control Panel\Cursors\Schemes"
if (-Not (Test-Path $schemePath)) {
    New-Item -Path $schemePath -Force | Out-Null
}

$schemeValue = (
    $cursorMappings["Arrow"] + "," +
    $cursorMappings["Help"] + "," +
    $cursorMappings["AppStarting"] + "," +
    $cursorMappings["Wait"] + "," +
    $cursorMappings["Crosshair"] + "," +
    $cursorMappings["IBeam"] + "," +
    $cursorMappings["NWPen"] + "," +
    $cursorMappings["No"] + "," +
    $cursorMappings["SizeNS"] + "," +
    $cursorMappings["SizeWE"] + "," +
    $cursorMappings["SizeNWSE"] + "," +
    $cursorMappings["SizeNESW"] + "," +
    $cursorMappings["SizeAll"] + "," +
    $cursorMappings["Hand"] + "," +
    $cursorMappings["UpArrow"]
)
Set-ItemProperty -Path $schemePath -Name "UwU" -Value $schemeValue

# Ustawianie aktywnego schematu na 'UwU' w rejestrze
Write-Host "Ustawianie aktywnego schematu na 'UwU'..."
Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "(Default)" -Value "UwU"

# Synchronizacja kursora z UI
Write-Host "Synchronizacja ustawień kursora..."
$schemePath = "HKCU:\Control Panel\Cursors"
foreach ($cursor in $cursorMappings.Keys) {
    Set-ItemProperty -Path $schemePath -Name $cursor -Value $cursorMappings[$cursor]
}

# Odświeżanie ustawień
Write-Host "Odświeżanie ustawień kursora..."
Rundll32.exe user32.dll,UpdatePerUserSystemParameters

# Wyświetlenie komunikatu o zakończeniu
Write-Host "Gotowe! Schemat 'UwU' został ustawiony jako aktywny."

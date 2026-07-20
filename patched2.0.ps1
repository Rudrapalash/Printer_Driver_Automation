$check = get-printerdriver | where-object {$_.Name -eq "FF Apeos 3060 PCL 6"}

$ErrorActionPreference = "Stop"

if ($null-eq $check) {
    
    try {
        # ------------------------------------------------------------------
        # Variables - EDIT THESE
        # ------------------------------------------------------------------
        $DownloadFolder   = "C:\Driver_Installer"
        $DriverExe        = Join-Path $DownloadFolder "Driver.exe"
        $ExtractFolder    = "C:\Driver_Installer\Extracted"
        $PrinterIP        = "172.23.20.20"
        $PortName         = "IP_$PrinterIP"
        $PrinterName      = "EastWingPrinter"

        
        $TargetDriverName = "FF Apeos 3060 PCL 6"

        # ------------------------------------------------------------------
        # 0. Require elevation
        # ------------------------------------------------------------------
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal(
            [Security.Principal.WindowsIdentity]::GetCurrent()
        )
        if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw "This script must be run as Administrator."
        }

        # ------------------------------------------------------------------
        # 1. Create required directories
        # ------------------------------------------------------------------
        New-Item -ItemType Directory -Path $DownloadFolder -Force | Out-Null
        New-Item -ItemType Directory -Path $ExtractFolder -Force | Out-Null

        # ------------------------------------------------------------------
        # 2. Download the driver
        # ------------------------------------------------------------------
        Invoke-WebRequest `
            -Uri "https://support-fb.fujifilm.com/tiles/common/hc_drivers_download.jsp?system=%27Windows%2011%2064bit%27&shortdesc=null&xcrealpath=OJ7/3Y0JABD2FrJ4m7x3OhhSUpny3LIjCz80yWGJWd6AciVZT/oSemkJS5E7YNzueui71PmrIxklhk+4yz2TlpQv02bcdMJ+DPLSaMCiY6M=" `
            -OutFile $DriverExe `
            -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3" `
            -UseBasicParsing

        Write-Host "Driver downloaded successfully." -ForegroundColor Green

        # ------------------------------------------------------------------
        # 3. Extract the driver
        # ------------------------------------------------------------------
        $SevenZip = "C:\Program Files\7-Zip\7z.exe"
        & $SevenZip x $DriverExe "-o$ExtractFolder" -y

        Write-Host "Driver extracted successfully." -ForegroundColor Green

        # ------------------------------------------------------------------
        # 4. Locate INF files that actually declare a printer class driver
        # ------------------------------------------------------------------
        $InfFiles = Get-ChildItem -Path $ExtractFolder -Filter "FFMO3PCLA.INF" -Recurse 
        $Inf = $InfFiles | Select-Object -First 1
        if (-not $Inf) { throw "FFMO3PCLA.INF not found under $ExtractFolder" }
        
        

            
        

    
        # Add Printer Driver
        pnputil /add-driver $InfFiles.FullName /install
        Add-PrinterDriver -Name $TargetDriverName 
    






        # ------------------------------------------------------------------
        # 6. Select which installed driver to use
        # ------------------------------------------------------------------
        if ($TargetDriverName) {
            $Driver = Get-PrinterDriver | Where-Object { $_.Name -eq $TargetDriverName }
            if (-not $Driver) {
                throw "Target driver '$TargetDriverName' was not found after installation. " +
                    "Installed drivers this run: $($InstalledDriverNames -join ', ')"
            }
        }
        

        Write-Host "Using printer driver: $($Driver.Name)" -ForegroundColor Cyan

        # ------------------------------------------------------------------
        # 7. Create the TCP/IP port if it doesn't exist
        # ------------------------------------------------------------------
        if (-not (Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue)) {
            Add-PrinterPort `
                -Name $PortName `
                -PrinterHostAddress $PrinterIP

            Write-Host "Printer port created." -ForegroundColor Green
        }
        else {
            Write-Host "Printer port already exists." -ForegroundColor Yellow
        }

        # ------------------------------------------------------------------
        # 8. Add the printer if it doesn't already exist
        # ------------------------------------------------------------------
        
            Add-Printer `
                -Name $PrinterName `
                -DriverName $Driver.Name `
                -PortName $PortName

            Write-Host "Printer added successfully." -ForegroundColor Green
       
    }
    catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }

}

else {
    Write-Host "Printer driver already installed. Skipping installation." -ForegroundColor Yellow
}
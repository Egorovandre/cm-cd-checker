[CmdletBinding()]
Param(
    #CM,CD,PR,CMPR,REP
    [Parameter(Mandatory = $true)] [string]$serverRole 
    #Solr,Lucene,Azure
    ,[Parameter(Mandatory = $True)] [string] $searchType
    #Todo: Need to add mode Type check, fix
    ,[Parameter(Mandatory = $False )][string]$runMode = "fix"
    , [Parameter(Mandatory = $False)] [string] $CsvSettingsFilePath = ".\settings\ConfigurationCsv.Settings.xml"
    , [Parameter(Mandatory = $False)] [string] $ApplicationFolderPath = "C:\inetpub\wwwroot\Lowes"
)

Write-Host "`r`nSitecore Role Validator`r`n`r`n"

Write-Host "To use this tool, ensure that you have configured the relevant settings in the `"$CsvSettingsFilePath`" file. The test will run once for each of the Roles that are added in the settings file. If any errors are encountered, resolve them in the CSV file and re-run the tool.`r`n" 
Write-Host "Note that the most common error occurs when a 'Config Type' and 'Config File Name' in the CSV does not match up for a particular file (i.e. the file is of type 'disabled' but its name ends in '.config' or '.example'). For these issues, find the referenced file in the unmodified Sitecore source and update the CSV according to what you find.`r`n"

Read-Host "Press [ENTER] to execute the tool"

#Log file parameters

$logfile = ".\logs\$(Get-Date -Format yyyyMMdd_HHmm).log"
Function LogWrite {
    Param ( [string]$logstring ) Add-content $logfile -value $logstring
    
}

Write-Host "Executing tests..."
#Check setting files 
if (-not (Test-Path -Path $CsvSettingsFilePath -PathType Leaf)) {
    throw [System.IO.FileNotFoundException] "File '$CsvSettingsFilePath' specified for parameter 'ConfiguratorScriptFilePath' was not found. This file is required and should be the file containing the Invoke-SitecoreRoleConfigurator commandlet."
}
# get the xml
[xml]$settings = Get-Content -Path $CsvSettingsFilePath
function Get-ValueOrDefault {
    Param([string] $Value, [string] $Default)
    if (!$Value) { return $Default } else { return $Value }
}
# apply default values from the XML settings, where needed
$CsvFilePath = Get-ValueOrDefault $CsvFilePath $settings.Parameters.CsvFilePath;
$FileNameColumn = Get-ValueOrDefault $FileNameColumn $settings.Parameters.FileNameColumnHeader
$FilePathColumn = Get-ValueOrDefault $FilePathColumn $settings.Parameters.FilePathColumnHeader
$DefaultExtensionColumn = Get-ValueOrDefault $DefaultExtensionColumn $settings.Parameters.DefaultExtensionColumnHeader
$SearchProviderColumn = Get-ValueOrDefault $SearchProviderColumn $settings.Parameters.SearchProviderColumnHeader

$searchEngine = "$($searchType) is used"
$csvTable = Import-Csv -Path $CsvFilePath | Select-Object "Product Name", "File Path", "Config file name", "Config Type", "Search Provider Used", $serverRole | Where-Object{$_."Search Provider Used" -eq $searchEngine -or $_."Search Provider Used" -eq ""}


foreach ($csvTableRow in $csvTable) {
    $configPath = Join-Path -Path $ApplicationFolderPath -ChildPath $csvTableRow.$FilePathColumn.Trim()
    $fileName = $csvTableRow.$FileNameColumn
    $defaultExtension = $csvTableRow.$DefaultExtensionColumn.Trim()
    $confStatus = $csvTableRow.$serverRole
    $configFile = $configPath + '\' + $fileName
    if ($confStatus -eq 'Enable') {
        if ($defaultExtension -eq 'config') {
            $nullConfig = $configFile.Trim('.disabled')
            $disabledConfig = $nullConfig+".disabled"
            if((![System.IO.File]::Exists($nullConfig)) -and (![System.IO.File]::Exists($disabledConfig))){
                #LogWrite -logstring "Config $nullConfig does not found"
            }
            if([System.IO.File]::Exists($disabledConfig)){
                if ($runMode -eq 'check') {
                    LogWrite -logstring "$nullConfig Must be ENABLED for $serverRole server"
                }else{
                    Rename-Item -Path $disabledConfig -NewName $nullConfig
                    LogWrite -logstring "$nullConfig ENABLED for $serverRole server"
                }
              
            }
        }
        if ($defaultExtension -eq 'example') {
            $nullConfig = $configFile.Trim('.example')
            $disabledConfig = $nullConfig+".example.disabled"
            if((![System.IO.File]::Exists($nullConfig)) -and (![System.IO.File]::Exists($disabledConfig))){
                #LogWrite -logstring "Example config $nullConfig does not found"
               
            }
            if([System.IO.File]::Exists($disabledConfig)){
                if ($runMode -eq 'check') {
                    LogWrite -logstring "$nullConfig MUST BE ENABLED for $searchType provider"
                }else{
                    Rename-Item -Path $disabledConfig -NewName $nullConfig
                    LogWrite -logstring "$nullConfig ENABLED for $searchType provider" 
                }
             
               
            }
        }
    }
    if ($confStatus -eq 'Disable') {
       
        if ($defaultExtension -eq 'config') {
            $nullConfig = $configFile.Trim('.disabled')
            $disabledConfig = $nullConfig+".disabled"
            if((![System.IO.File]::Exists($nullConfig)) -and (![System.IO.File]::Exists($disabledConfig))){
                #LogWrite -logstring "Config $nullConfig does not found"
            }
            if([System.IO.File]::Exists($nullConfig)){
                if ($runMode -eq 'check') {
                    LogWrite -logstring "$nullConfig MUST BE DISABLED for $serverRole server"
                } else {
                    Rename-Item -Path $nullConfig -NewName $disabledConfig
                    LogWrite -logstring "$nullConfig DISABLED for $serverRole server"
                }
               
                
            }
            if ($defaultExtension -eq 'example') {
                $nullConfig = $configFile.Trim('.example')
                $disabledConfig = $nullConfig+".example.disabled"
                if((![System.IO.File]::Exists($nullConfig)) -and (![System.IO.File]::Exists($disabledConfig))){
                    #LogWrite -logstring "Example config $nullConfig does not found"
                   
                }
                if([System.IO.File]::Exists($nullConfig)){
                    if ($runMode -eq 'check') {
                        LogWrite -logstring "$nullConfig MUST BE DISABLED for $serverRole server" 
                    }else{
                        Rename-Item -Path $nullConfig -NewName $disabledConfig
                        LogWrite -logstring "$nullConfig DISABLED for $serverRole server"
                    }
                 }
            }
        }
    }
    
}
Write-Host "Test Completed."
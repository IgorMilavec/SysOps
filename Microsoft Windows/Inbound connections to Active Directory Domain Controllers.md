
Inbound connections to Active Directory Domain Controllers
==========================================================

## DNS Server
  * 53/tcp
  * 53/udp

## DHCP Server
  * 67/udp 

## SMB Server
  * 445/tcp

## DCE RPC Locator
  * 135/tcp

## Active Directory Domain Services
  * 88/tcp
  * 389/tcp
  * 636/tcp (tls)
  * 464/tcp
  * 3268/tcp
  * 3269/tcp (tls)
  * various DCE RPC endpoints with dynamic ports, which have a relatively stable assignment

A full list including the currently assigned dynamic ports can be obtained running this script on the Domain Controller:
``` powershell
Get-NetTCPConnection -OwningProcess (Get-Process -Name lsass Select-Object -ExpandProperty Id) -State Listen | Select-Object -ExpandProperty LocalPort | Sort-Object -Unique
```

## Active Directory Web Services
  * 9389/tcp

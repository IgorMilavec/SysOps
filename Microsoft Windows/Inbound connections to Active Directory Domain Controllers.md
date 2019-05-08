
Inbound connections to Active Directory Domain Controllers
==========================================================

## DNS Server
  * 53/tcp
  * 53/udp

## DHCP Server
  * 67/udp 

## SMB Server
  * 445/tcp

## SNTP Server
  * 123/udp

## DCE RPC Locator
  * 135/tcp

## Active Directory Domain Services
  * 88/tcp
  * 88/udp
  * 389/tcp
  * 636/tcp (tls)
  * 464/tcp
  * 464/udp
  * 3268/tcp
  * 3269/tcp (tls)
  * various DCE RPC endpoints with dynamic ports

A full list including the currently assigned dynamic ports can be obtained running this script on the Domain Controller:
``` powershell
Get-NetTCPConnection -OwningProcess (Get-Process -Name lsass | Select-Object -ExpandProperty Id) -State Listen | Select-Object -ExpandProperty LocalPort | Sort-Object -Unique
```
Some of the dynamic ports can be fixed, see [KB224196](https://support.microsoft.com/en-us/help/224196/restricting-active-directory-rpc-traffic-to-a-specific-port).

## Active Directory Web Services
  * 9389/tcp

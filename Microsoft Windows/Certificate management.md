
List certificates that are in the wrong store:
```PowerShell
dir Cert:\LocalMachine\AuthRoot | ?{ $_.Issuer -ne $_.Subject } | fl Thumbprint,Subject,Issuer
dir Cert:\LocalMachine\Root | ?{ $_.Issuer -ne $_.Subject } | fl Thumbprint,Subject,Issuer
dir Cert:\LocalMachine\CA | ?{ $_.Issuer -eq $_.Subject } | fl Thumbprint,Subject,Issuer
```

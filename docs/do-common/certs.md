# :material-certificate: Certificates

Functions for working with X509 certificates - inspecting chains, converting between PEM and .NET
objects, and managing root certificates.

| Function                    | Alias    | Description               |
| --------------------------- | -------- | ------------------------- |
| `Add-CertificateProperties` |          | Add CN, SAN, SKI, AKI     |
| `ConvertFrom-PEM`           |          | PEM string to X509 object |
| `ConvertTo-PEM`             |          | X509 object to PEM string |
| `Get-Certificate`           |          | Get cert(s) from URI      |
| `Get-CertificateOpenSSL`    |          | Get cert(s) via OpenSSL   |
| `Get-RootCertificates`      |          | List system root certs    |
| `Show-Certificate`          |          | Show cert chain for URI   |
| `Show-CertificateChain`     |          | Show full cert chain      |
| `Show-ConvertedPem`         | `pemdec` | Decode and display PEM    |

!!! example "Inspect a certificate chain"
    ```powershell
    Show-Certificate -Uri 'https://github.com'
    ```

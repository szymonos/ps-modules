Describe 'ConvertFrom-PEM' {
    Context 'When given a PEM encoded certificate string' {
        It 'Should convert it to X509Certificate2 object' {
            $path = Join-Path $PSScriptRoot -ChildPath 'certs.pem'
            $pem = [System.IO.File]::ReadAllText($path)
            $result = ConvertFrom-PEM -InputObject $pem

            $result | Should -BeOfType [System.Security.Cryptography.X509Certificates.X509Certificate2]
            $result.Count | Should -Be 2
        }

    }

    Context 'When given a path to a PEM encoded certificate file' {
        It 'Should convert it to X509Certificate2 object' {
            $path = Join-Path $PSScriptRoot -ChildPath 'certs.pem'

            $result = ConvertFrom-PEM -Path $path

            $result | Should -BeOfType [System.Security.Cryptography.X509Certificates.X509Certificate2]
            $result.Count | Should -Be 2
        }
    }
}

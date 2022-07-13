class parky {
    [string]$baseuri = "https://parko.giantleap.no"
    $useragent = 'Android/Cardboard(trondheimparkering-4.9.13)/1.3.28'
    [string]$phoneNumber = ''
    $session = $null
    [string]$token = ''
    [string]$refresh_token = ''
    [string]$userId = ''
    [string]$code = ''
    [string]$place = ""
    [string]$clientIdentifier = "SNWKJJSP7NZ4J1DY"
    [System.Object]$productPaths = @{}
    [System.Object]$productVariants = @{}
    $baseheaders = @{
        "x-gltlocale" = "en_US_trondheimparkering"
        "x-partnerid" = "trondheimparkering"
        "accept-encoding" = "gzip"
        "user-agent" = $this.useragent
        "content-type" = "application/json;charset=UTF-8"
        "host" = "parko.giantleap.no"
    }

    # Constructor
    parky([string]$phoneNumber) {
        $this.session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        #$this.session.UserAgent = $this.useragent

        $newPhoneNumber = $phoneNumber.Replace(' ','') 

        if ($newPhoneNumber -notmatch "^\+|00") {
            # Missing countrycode
            $newPhoneNumber = "+47$newPhoneNumber"
        }

        $this.phoneNumber = $newPhoneNumber
    }

    setPlace([string]$place) {
        $this.place = $place
    }

    [System.Object]GetMfaCode () {
        $uri = "$($this.baseuri)/client/suc-request"
        $headers = $this.baseheaders

        $payLoad = @{
            "phoneNumber" = $this.phoneNumber
        }

        $payLoadJson = $payLoad | ConvertTo-Json
        Write-Host -f yellow "$uri"
        $res = Invoke-RestMethod -Method "POST" -Uri $uri -WebSession $this.session -Headers $headers -Body $payLoadJson -SkipHeaderValidation

        if ($res.resultCode -eq 'SUCCESS') {
            Write-Host -f Green $res.resultCode
        } else {
            Write-Host -f Red $res.resultCode
        }
        return $res
    }

    [System.Object]VerifyMfaCode ([string]$code) {
        $uri = "$($this.baseuri)/client/suc-verify"
        $headers = $this.baseheaders

        $payLoad = @{
            "phoneNumber" = $this.phoneNumber
            "code" = $code
        }

        $payLoadJson = $payLoad | ConvertTo-Json
        write-Host -f yellow "$uri"
        $res = Invoke-RestMethod -Method "POST" -Uri $uri -WebSession $this.session -Headers $headers -Body $payLoadJson -SkipHeaderValidation

        if ($res.resultCode -eq 'SUCCESS') {
            Write-Host -f Green $res.resultCode
            $this.token = $res.token
            $this.refresh_token = $res.refreshToken
            $this.userId = $res.userId
        } else {
            Write-Host -f Red $res.resultCode
        }

        return $res
    }

    [System.Object]GetProducts() {
        $uri = "$($this.baseuri)/permit/dynamic/products?placeId=ALL_PLACES&category=PERMIT"
        $headers = $this.baseheaders

        $headers['x-token'] = $this.token

        write-Host -f yellow "$uri"
        $res = Invoke-RestMethod -Method "GET" -Uri $uri -WebSession $this.session -Headers $headers -SkipHeaderValidation

        if ($res.resultCode -eq 'SUCCESS') {
            Write-Host -f Green $res.resultCode

            foreach ($product in $res.sections.elements) {
                Write-Host $product.title
                $this.productPaths["$($product.title)"] = $product.Path
            }

        } else {
            Write-Host -f Red $res.resultCode
        }

        return $res
    }

    [System.Object]GetVariants([string]$name) {

        $subpath = $this.productPaths["$name"]
        $uri = "$($this.baseuri)$subpath"
        
        $headers = $this.baseheaders
        $headers['x-token'] = $this.token

        write-Host -f yellow "$uri"
        $res = Invoke-RestMethod -Method "GET" -Uri $uri -WebSession $this.session -Headers $headers -SkipHeaderValidation

        $result = if ($res.resultCode -eq 'SUCCESS') {
            Write-Host -f Green $res.resultCode

            foreach ($variant in $res.sections.elements) {
                $this.InvokeRest($variant.path)
            }
        } else {
            Write-Host -f Red $res.resultCode
        }

        return $result.product.variants
    }

    [System.Object]InvokeRest($path) {
        $uri = "$($this.baseuri)$path"
        
        $headers = $this.baseheaders
        $headers['x-token'] = $this.token

        write-Host -f yellow "$uri"
        $res = Invoke-RestMethod -Method "GET" -Uri $uri -WebSession $this.session -Headers $headers -SkipHeaderValidation

        if ($res.resultCode -eq 'SUCCESS') {
            Write-Host -f Green $res.resultCode
        } else {
            Write-Host -f Red $res.resultCode
        }

        return $res
    }

    [System.Object]getLicensePlate($plateNumber) {
        $path = "/vehicle/lookup?regNo=$plateNumber"
        $res = $this.InvokeRest($path)
        return $res
    }

    [System.Object]InvokeParking($plateNumber, $productVariantId) {
        $subpath = "/permit/aquire"
        $uri = "$($this.baseuri)$subpath"
        
        $headers = $this.baseheaders
        $headers['x-token'] = $this.token

        $today = (Get-date).ToString("yyyy-MM-dd")

        $payLoadJson = @"
        {
            `"formData`": [
                {
                    `"name`": `"note`"
                },
                {
                    `"name`": `"plate_number_1`",
                    `"value`": `"$plateNumber`"
                },
                {
                    `"name`": `"start_date`",
                    `"value`": `"$today`"
                }
            ],
            `"productVariantId`": `"$productVariantId`"
        }
"@

        write-Host -f yellow "$uri"
        $res = Invoke-RestMethod -Method "POST" -Uri $uri -WebSession $this.session -Headers $headers -SkipHeaderValidation -Body $payLoadJson

        return $res
    }

    [System.Object]getActive() {
        $subpath = "/permit/list"
        $uri = "$($this.baseuri)$subpath"
        
        $headers = $this.baseheaders
        $headers['x-token'] = $this.token

        write-Host -f yellow "$uri"
        $res = Invoke-RestMethod -Method "POST" -Uri $uri -WebSession $this.session -Headers $headers -Body "" -SkipHeaderValidation

        if ($res.resultCode -eq 'SUCCESS') {
            Write-Host -f Green $res.resultCode
            $info = $res.permits

            Write-Host -f Green "Name : " -NoNewline
            Write-Host "$($info.name) $($info.id)"
            Write-Host -f Green "Car : " -NoNewline
            Write-Host "$($info.formfields[0].value)"
            Write-Host -f Green "Valid From: " -NoNewline
            Write-Host "$($info.validFrom)"
            Write-Host -f Green "Expires At: " -NoNewline
            Write-Host "$($info.expiresAt)"


        } else {
            Write-Host -f Red $res.resultCode
        }

        return $res
    }

    [System.Object]Reauth() {
        $subpath = "/client/reauth"
        $uri = "$($this.baseuri)$subpath"
        
        $headers = $this.baseheaders
        $headers['x-token'] = $this.token

        $payLoad = @{
            clientIdentifier = $this.clientIdentifier
            refreshToken = $this.refresh_token
        }

        $jsonPayLoad = $payLoad | ConvertTo-Json

        write-Host -f yellow "$uri"
        $res = Invoke-RestMethod -Method "POST" -Uri $uri -WebSession $this.session -Headers $headers -SkipHeaderValidation -Body $jsonPayLoad

        if ($res.resultCode -eq 'SUCCESS') {
            Write-Host -f Green $res.resultCode
            $this.token = $res.token
        } else {
            Write-Host -f Red $res.resultCode
        }

        return $res
    }

}
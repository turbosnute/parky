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
        write-verbose -f yellow "$uri"
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
        } else {
            Write-Host -f Red $res.resultCode
        }

        return $res
    }

}

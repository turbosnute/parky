# parky

## Basic Usage

Load the class
```
. .\parky.ps1
```
Create new parky object. With your cell phone number (for authentication).
```
$park = [parky]::new("+47 81549300")
```

Get MFA code (SMS)
```
$park.GetMfaCode()
```

Verify MFA code
```
$park.VerifyMfaCode("1234")
```

Get products
```
$park.GetProducts()
```

Get available parking variants for a selected product
```
$park.GetVariants("Ansatteparkering NTNU")
https://parko.giantleap.no/permit/dynamic/variants?productId=8a80a1b58119645101811df9307a04fb&category=PERMIT
SUCCESS
https://parko.giantleap.no/permit/product/variant?variantId=5901db24-d330-4f9e-934a-1e1623d3d1f5
SUCCESS

id           : 5901db24-d330-4f9e-934a-1e1623d3d1f5
scope        : Ansatteparkering NTNU
description  :
priceCents   : 0
termsUrl     :
formFields   : {@{...}
availability : @{...}
```

Start parking
```
$park.InvokeParking("HB12345","5901db24-d330-4f9e-934a-1e1623d3d1f5")
```

List active permits
```
$park.getActive()

Name : Ansatteparkering NTNU
Car : HB12345
Valid From: 2022-07-13 12:41:59
Expires At: 2022-07-13 21:41:59


```

## Advanced
Manually set tokens
```
$park = [parky]::new("+47 81549300")

$park.userId = '1000000'
$park.token = 'aaa123456-a123-4444-4444-444444444444|444444444444/aaaaaaaaa=='
$park.refresh_token = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
```
Keep the session alive. (refresh the token)
```
$park.Reauth()
```
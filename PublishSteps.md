# Publishing
This file outlines the steps to publish to the [PowerShell Gallery](https://www.powershellgallery.com/).

## Getting the API key
Sign in to  [PowerShell Gallery](https://www.powershellgallery.com/) and go to your account page (click on your name in the top right).

You will see you account key listed, copy it and run the following in a PowerShell console:

```posh
$powershellGalleryKey="011053b4-5968-4ef1-8c05-127b05d4a665"
```
(No, that's not my real key!)

## Publishing the module

* Check that the module version (src/riddlerps/riddlerps.psd1) has been updated
* Run the `Publish-Module` cmdlet from the root of the repo (and in the same console as you set your API key above)


```posh
Publish-Module -Path .\src\riddlerps\ -NuGetApiKey $powershellGalleryKey
```
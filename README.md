# HSURL
Bash script to set or unset IASUCatalogURL to bypass issues with High Sierra's recovery env and HTTPS.

***

```
usage: HSURL.command [-h] [-1] [-2] [-o] [-n] [-u URL] [-s HOST] [-p PORT]

HSURL - a bash script to set or unset IASUCatalogURL to bypass HTTPS on 10.13

optional arguments:
  -h, --help              show this help message and exit
  -1, --set-url           sets the URL in NVRAM without menu interaction
  -2, --unset-url         unsets the URL from NVRAM without menu interaction
  -o, --override-os       override the OS check for 10.13.x
  -n, --skip-network      skips the check for a network connection
  -u URL, --url URL       override the URL to use for IASUCatalogURL
  -s HOST, --host HOST    override the apple.com host in the network check
  -p PORT, --port PORT    override port 80 in the network check
```

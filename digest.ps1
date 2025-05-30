# digest.ps1
# PowerShell script to store visible text content of main pages and common sections of a website into a single XML file

param(
    [Parameter(Mandatory=$true)]
    [string]$url
)

# Get website title for output file name
try {
    $mainPage = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop | Select-Object -ExpandProperty Content
    $titleMatch = [regex]::Match($mainPage, '<title>(.*?)</title>', 'IgnoreCase')
    if ($titleMatch.Success) {
        $siteTitle = $titleMatch.Groups[1].Value -replace '[^\w\-]', '_'
    } else {
        $siteTitle = 'website'
    }
} catch {
    $siteTitle = 'website'
}
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$xmlFile = "${siteTitle}_$timestamp.xml"

$xml = New-Object System.Xml.XmlDocument
$declaration = $xml.CreateXmlDeclaration("1.0", "UTF-8", $null)
$xml.AppendChild($declaration) | Out-Null
$root = $xml.CreateElement("websiteTextContent")
$xml.AppendChild($root) | Out-Null

# Fetch the main page and extract top menu links
try {
    $mainPageContent = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop | Select-Object -ExpandProperty Content
    Write-Host ("Fetched main page for menu extraction: {0}" -f $url)
} catch {
    Write-Host ("Failed to fetch main page for menu extraction: {0}" -f $url)
    $mainPageContent = $null
}

$menuLinks = @()
if ($mainPageContent) {
    # Try to extract hrefs from <nav> or <ul> elements (common for top menus)
    $menuMatches = [regex]::Matches($mainPageContent, '<nav[\s\S]*?</nav>', 'IgnoreCase')
    if ($menuMatches.Count -eq 0) {
        $menuMatches = [regex]::Matches($mainPageContent, '<ul[\s\S]*?</ul>', 'IgnoreCase')
    }
    foreach ($menu in $menuMatches) {
        $hrefs = [regex]::Matches($menu.Value, 'href=["'']([^"'']+)["'']', 'IgnoreCase')
        foreach ($h in $hrefs) {
            $link = $h.Groups[1].Value
            if ($link.StartsWith("http")) {
                $menuLinks += $link
            } elseif ($link.StartsWith("/")) {
                $menuLinks += ($url.TrimEnd("/\") + $link)
            } elseif ($link -ne "") {
                $menuLinks += ($url.TrimEnd("/\") + "/" + $link)
            }
        }
    }
    $menuLinks = $menuLinks | Sort-Object -Unique
}

if (-not $menuLinks -or $menuLinks.Count -eq 0) {
    Write-Host "No menu links found, defaulting to main page only."
    $menuLinks = @($url)
}

foreach ($nextUrl in $menuLinks) {
    Write-Host ("Processing: {0}" -f $nextUrl)
    try {
        $pageContent = Invoke-WebRequest -Uri $nextUrl -UseBasicParsing -ErrorAction Stop | Select-Object -ExpandProperty Content
        Write-Host ("Fetched content for {0}" -f $nextUrl)
    } catch {
        Write-Host ("Failed to fetch {0}: {1}" -f $nextUrl, $_)
        continue
    }
    if (-not $pageContent) {
        Write-Host ("No content for {0}" -f $nextUrl)
        continue
    }
    # Extract visible text from HTML (remove tags, keep text)
    $text = $pageContent -replace '(?s)<script.*?</script>', '' -replace '(?s)<style.*?</style>', ''
    $text = $text -replace '<[^>]+>', ' '
    $text = $text -replace '&[a-zA-Z0-9#]+;', ' '  # Remove HTML entities
    $text = $text -replace '\s+', ' '              # Collapse whitespace
    $text = $text.Trim()
    Write-Host ("Extracted text length for {0}: {1}" -f $nextUrl, $text.Length)
    $pageElem = $xml.CreateElement("page")
    $urlElem = $xml.CreateElement("url")
    $urlElem.InnerText = $nextUrl
    $textElem = $xml.CreateElement("text")
    $textElem.InnerText = $text
    $pageElem.AppendChild($urlElem) | Out-Null
    $pageElem.AppendChild($textElem) | Out-Null
    $root.AppendChild($pageElem) | Out-Null
}

$xml.Save($xmlFile)
Write-Host "All top menu page text content stored in $xmlFile"

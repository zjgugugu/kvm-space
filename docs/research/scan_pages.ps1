$dir = "e:\code\kvm-space\docs\research\mc_pages"
$files = Get-ChildItem "$dir\*.html"
$results = @()
foreach ($f in $files) {
    $content = Get-Content $f.FullName -Raw -Encoding UTF8
    if ($content -match 'HTTP Status 404') {
        $results += "404: $($f.Name)"
    } else {
        $title = ''
        if ($content -match '<title>(.*?)</title>') {
            $title = $Matches[1]
        }
        $results += "OK: $($f.Name) -> $title"
    }
}
$results | Sort-Object

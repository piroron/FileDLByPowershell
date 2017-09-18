#URL形式のチェック
function IsCorrectUrl([string] $url){
    return [System.Uri]::IsWellFormedUriString($url, [System.UriKind]::Absolute);
}

$targetUrl = $Args[0];

# SSL/TLSのエラーが発生する場合、以下のコメントアウトを解除して、再度実行してみてください。
# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (-not (IsCorrectUrl($targetUrl))) {
    Write-Output "$targetUrl は正しい形式のURLではありません。"
    exit;
}

Write-Output ダウンロード対象
Write-Output $targetUrl
$uri = New-Object System.Uri ($targetUrl);

Write-Output ""

$saveDirectoryName = Get-Date -Format "yyyyMMddHHmmss";

$savePath = New-Item $saveDirectoryName -ItemType Directory -Force

Write-Output 出力先
Write-Output $savePath.FullName;

Write-Output ""

Write-Output ダウンロードを開始します。

try{
    #Webページを取得
    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing
    
    $links = $response.Links | Where-Object {$_.href -like "*.pdf"} | Select-Object -ExpandProperty href

    if ($links.Count -eq 0) {
        Write-Output ダウンロード対象のファイルがありません。
        return;
    }

    #個々のファイルダウンロード
    foreach($link in $links){
        #ファイル名抽出
        $fileName = Split-Path $link -Leaf
        
        #保存先パス作成（フォルダ + ファイル名）
        $outFilePath = Join-Path $savePath $fileName

        #DL対象ファイルのURL取得（Uriの機能で、絶対パスと相対パスをくっつける）
        $downloadUrl = New-Object System.Uri ($uri, $link)
        
        Invoke-WebRequest -Uri $downloadUrl.AbsoluteUri -OutFile　$outFilePath
        Write-Output "$fileName をダウンロードしました。"
    }
}catch [System.Net.WebException]{
    $statusCode = $_.Exception.Response.StatusCode;

    Write-Output エラー発生のため、処理を中断します。

    Write-Output "エラーステータス： $statusCode"
}

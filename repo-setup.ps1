[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory,
        HelpMessage = "The ID of the module. Must be lowercase alphanumeric and can include dashes."
    )]
    [Alias("i")]
    [ValidatePattern("^[a-z-]+$")]
    [string]
    $Id,

    [Parameter(Mandatory,
        HelpMessage = "The title of the module."
    )]
    [Alias("t")]
    [string]
    $Title,

    [Parameter(Mandatory,
        HelpMessage = "The description of the module."
    )]
    [Alias("d")]
    [string]
    $Description,

    [Parameter(Mandatory,
        HelpMessage = "The author's name for the module."
    )]
    [Alias("n")]
    [string]
    $AuthorName,

    [Parameter(Mandatory,
        HelpMessage = "The author's email for the module."
    )]
    [Alias("e")]
    [string]
    $AuthorEmail,

    [Parameter(
        HelpMessage = "The class name of the module in the sourtce code. When not specified, it will be a PascalCase version of the ID."
    )]
    [Alias("c")]
    [ValidatePattern("^[A-Z][a-zA-Z0-9]*$")]
    [string]
    $ClassName = $(AsPascalCase -KebabCaseString $Id)
)

function AsPascalCase {
    param (
        [Parameter(Mandatory)]
        [string]
        $KebabCaseString
    )
    return ($KebabCaseString -split '-') | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1) } -join ''
}

$KebabReplacement = [PSCustomObject] { key = "todo-module-id"; value = $Id }
$UpperCaseKebabReplacement = [PSCustomObject] { key = "TODO-MODULE-ID"; value = $Id.ToUpper() }
$ClassNameReplacement = [PSCustomObject] { key = "TodoMyModule"; value = $ClassName }

$Operations = @(
    [PSCustomObject] {
        file = "src/languages/en.json"
        repalcements = @(
            $UpperCaseKebabReplacement
        )
    },
    [PSCustomObject] {
        file = "src/templates/dogs.hbs"
        repalcements = @(
            $UpperCaseKebabReplacement 
        )
    },
    [PSCustomObject] {
        file = "src/ts/apps/dogBrowser.ts"
        repalcements = @(
            $UpperCaseKebabReplacement
        )
    },
    [PSCustomObject] {
        file = "src/ts/module.ts"
        repalcements = @(
            $ClassNameReplacement
        )
    },
    [PSCustomObject] {
        file = "src/ts/types.ts"
        repalcements = @(
            $ClassNameReplacement
        )
    },
    [PSCustomObject] {
        file = "module.json"
        repalcements = @(
            $KebabReplacement,
            [PSCustomObject] { key = "todo-module-title"; value = $Title },
            [PSCustomObject] { key = "todo-module-description"; value = $Description },
            [PSCustomObject] { key = "todo-module-author-name"; value = $AuthorName },
            [PSCustomObject] { key = "todo-module-author-email"; value = $AuthorEmail }
        )
    }
    [PSCustomObject] {
        file = "package.json"
        repalcements = @(
            $KebabReplacement,
            [PSCustomObject] { key = "todo-module-description"; value = $Description }
        )
    }
)

foreach ($Operation in $Operations) {
    $FilePath = Join-Path -Path $PSScriptRoot -ChildPath $Operation.file
    if (Test-Path -Path $FilePath) {
        $OriginalContent = Get-Content -Path $FilePath -Raw
        $NewContent = $OriginalContent
        foreach ($Replacement in $Operation.repalcements) {
            $NewContent = $NewContent -replace $Replacement.key, $Replacement.value
        }
        
        $ModifiedLines = @()
        if ($WhatIfPreference) {
            $OriginalLines = $OriginalContent -split "`n"
            $NewLines = $NewContent -split "`n"
            for ($i = 0; $i -lt $OriginalLines.Count; $i++) {
                $ModifiedLines += "Line $($i + 1):\n  Original: $($OriginalLines[$i])\n  New: $($NewLines[$i])"
            }
        }

        if ($PSCmdlet.ShouldProcess("Replacing content of $FilePath with:\n" + $ModifiedLines -join "\n", $FilePath, "Update content")) {
            Set-Content -Path $FilePath -Value $NewContent
        }
    }
    else {
        Write-Error "File not found: $FilePath"
    }
}

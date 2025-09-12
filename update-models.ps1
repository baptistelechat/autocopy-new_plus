#Requires -Version 7.0
<#
.SYNOPSIS
    Script de mise à jour automatique des modèles PowerToys New+
.DESCRIPTION
    Copie les fichiers et dossiers spécifiés dans files.txt vers le dossier des modèles PowerToys,
    en excluant les extensions listées dans banlist.txt
.AUTHOR
    Baptiste LECHAT
#>

# ============================================================================
# CONFIGURATION
# ============================================================================
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$fileList = Join-Path $scriptPath "files.txt"
$banListFile = Join-Path $scriptPath "banlist.txt"
$logFile = Join-Path $scriptPath "update-models.log"
$destFolder = "$env:LOCALAPPDATA\Microsoft\PowerToys\NewPlus\Modèles"

# ============================================================================
# FONCTIONS
# ============================================================================
function Write-Log {
  <#
    .SYNOPSIS
        Écrit un message dans le fichier de log et l'affiche à l'écran
    #>
  param(
    [Parameter(Mandatory = $true)]
    [string]$Message
  )
    
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $entry = "[$timestamp] $Message"
  Add-Content -Path $logFile -Value $entry -Encoding UTF8
  Write-Output $entry
}

# ============================================================================
# SCRIPT PRINCIPAL
# ============================================================================

Write-Log "🔄 Début de la mise à jour des modèles PowerToys..."

# Vérification de l'existence des fichiers de configuration
if (-Not (Test-Path $fileList)) {
  Write-Log "❌ Le fichier files.txt est introuvable."
  exit 1
}
if (-Not (Test-Path $banListFile)) {
  Write-Log "❌ Le fichier banlist.txt est introuvable."
  exit 1
}

# Création du dossier de destination s'il n'existe pas
if (-Not (Test-Path $destFolder)) {
  New-Item -Path $destFolder -ItemType Directory -Force | Out-Null
  Write-Log "📁 Dossier de destination créé : $destFolder"
}

# Lecture et préparation des données
Write-Log "📋 Lecture des fichiers de configuration..."
$banExtensions = Get-Content $banListFile -Encoding UTF8 | 
Where-Object { $_.Trim() -ne "" } | 
ForEach-Object { $_.Trim().ToLower() }

$entries = Get-Content $fileList -Encoding UTF8 | 
Where-Object { $_.Trim() -ne "" } | 
ForEach-Object { $_.Trim('"').Trim() }

Write-Log "📊 Extensions bannies : $($banExtensions.Count)"
Write-Log "📊 Entrées à traiter : $($entries.Count)"

# Traitement de chaque entrée
$processedCount = 0
$errorCount = 0

foreach ($entry in $entries) {
  $processedCount++
  Write-Log "🔄 [$processedCount/$($entries.Count)] Traitement : $entry"
    
  if ($entry.EndsWith("*")) {
    # CAS 1: Copie du contenu d'un dossier uniquement (pas le dossier lui-même)
    $folder = $entry.TrimEnd("*", "\")
        
    if (Test-Path $folder -PathType Container) {
      Write-Log "📂 Copie du contenu du dossier : $folder"
            
      try {
        $files = Get-ChildItem -Path $folder -File -Recurse -ErrorAction Stop
        $validFiles = $files | Where-Object { 
          $banExtensions -notcontains $_.Extension.ToLower() 
        }
                
        Write-Log "📊 Fichiers trouvés : $($files.Count) | Fichiers valides : $($validFiles.Count)"
                
        foreach ($file in $validFiles) {
          $destFile = Join-Path $destFolder $file.Name
          try {
            Copy-Item -Path $file.FullName -Destination $destFile -Force -ErrorAction Stop
            Write-Log "✅ Copié : $($file.Name)"
          }
          catch {
            Write-Log "❌ Erreur lors de la copie de $($file.Name) : $_"
            $errorCount++
          }
        }
                
        # Log des fichiers ignorés
        $bannedFiles = $files | Where-Object { 
          $banExtensions -contains $_.Extension.ToLower() 
        }
        foreach ($bannedFile in $bannedFiles) {
          Write-Log "⏭️ Ignoré (extension bannie) : $($bannedFile.Name)"
        }
      }
      catch {
        Write-Log "❌ Erreur lors de la lecture du dossier $folder : $_"
        $errorCount++
      }
    }
    else {
      Write-Log "⚠️ Dossier introuvable : $folder"
      $errorCount++
    }
  }
  elseif (Test-Path $entry -PathType Container) {
    # CAS 2: Copie d'un dossier entier avec sa structure
    $folderName = Split-Path $entry -Leaf
    $destPath = Join-Path $destFolder $folderName
        
    try {
      Write-Log "📦 Copie du dossier complet : $entry"
            
      # Suppression du dossier de destination s'il existe déjà
      if (Test-Path $destPath) {
        Remove-Item -Path $destPath -Recurse -Force -ErrorAction Stop
        Write-Log "🗑️ Ancien dossier supprimé : $folderName"
      }
            
      # Copie avec exclusion des extensions bannies
      $excludePatterns = $banExtensions | ForEach-Object { "*$_" }
      Copy-Item -Path $entry -Destination $destPath -Recurse -Force -Exclude $excludePatterns -ErrorAction Stop
            
      Write-Log "✅ Dossier copié : $folderName"
    }
    catch {
      Write-Log "❌ Erreur lors de la copie du dossier $folderName : $_"
      $errorCount++
    }
  }
  elseif (Test-Path $entry -PathType Leaf) {
    # CAS 3: Copie d'un fichier unique
    $fileName = Split-Path $entry -Leaf
    $fileExtension = [System.IO.Path]::GetExtension($fileName).ToLower()
        
    if ($banExtensions -contains $fileExtension) {
      Write-Log "⏭️ Ignoré (extension bannie) : $fileName"
      continue
    }
        
    $destFile = Join-Path $destFolder $fileName
    try {
      Copy-Item -Path $entry -Destination $destFile -Force -ErrorAction Stop
      Write-Log "✅ Fichier copié : $fileName"
    }
    catch {
      Write-Log "❌ Erreur lors de la copie de $fileName : $_"
      $errorCount++
    }
  }
  else {
    Write-Log "⚠️ Chemin introuvable : $entry"
    $errorCount++
  }
}

# ============================================================================
# RÉSUMÉ ET FINALISATION
# ============================================================================

# Affichage du résumé des opérations
Write-Log " " # Ligne vide pour la lisibilité
Write-Log "📊 RÉSUMÉ DES OPÉRATIONS"
Write-Log "═══════════════════════════════════════"
Write-Log "📁 Entrées traitées : $processedCount/$($entries.Count)"
Write-Log "❌ Erreurs rencontrées : $errorCount"

if ($errorCount -eq 0) {
  Write-Log "🎉 Mise à jour terminée avec succès !"
  $exitCode = 0
}
else {
  Write-Log "⚠️ Mise à jour terminée avec des erreurs."
  $exitCode = 1
}

Write-Log "📝 Log complet disponible : $logFile"
Write-Log " " # Ligne vide

exit $exitCode

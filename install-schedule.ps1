#Requires -Version 7.0
<#
.SYNOPSIS
    Script d'installation de la tâche planifiée PowerToys New+ avec vérification admin
.DESCRIPTION
    Installe une tâche planifiée pour la mise à jour automatique des modèles PowerToys.
    Se relance automatiquement en mode administrateur si nécessaire.
#>

# ============================================================================
# VÉRIFICATION DES PRIVILÈGES ADMINISTRATEUR
# ============================================================================

# Fonction pour vérifier si le script s'exécute en tant qu'administrateur
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Si pas admin, relancer en mode administrateur
if (-not (Test-IsAdmin)) {
    Write-Output "⚠️ Privilèges administrateur requis pour créer une tâche planifiée."
    Write-Output "🔄 Relance du script en mode administrateur..."
    
    try {
        $scriptPath = $MyInvocation.MyCommand.Path
        Start-Process -FilePath "pwsh.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs -Wait
        Write-Output "✅ Script exécuté en mode administrateur."
        exit 0
    }
    catch {
        Write-Output "❌ Impossible de relancer en mode administrateur : $_"
        Write-Output "⚠️ Veuillez exécuter ce script en tant qu'administrateur manuellement."
        Read-Host "Appuyez sur Entrée pour fermer"
        exit 1
    }
}

Write-Output "✅ Exécution en mode administrateur confirmée."
Write-Output ""

# ============================================================================
# CONFIGURATION
# ============================================================================

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$mainScript = Join-Path $scriptPath "update-models.ps1"
$taskName = "UpdatePowerToysModels"
$triggersFile = Join-Path $scriptPath "triggers.txt"

# --- Vérification du script principal ---
if (-Not (Test-Path $mainScript)) {
  Write-Output "❌ Le script update-models.ps1 est introuvable à : $mainScript"
  exit
}

# --- Vérification du fichier triggers.txt ---
if (-Not (Test-Path $triggersFile)) {
  Write-Output "❌ Le fichier triggers.txt est introuvable à : $triggersFile"
  exit
}

# --- SUPPRESSION ANCIENNE TACHE ---
try {
  $oldTasks = Get-ScheduledTask | Where-Object { $_.TaskName -eq $taskName }
  if ($oldTasks) {
    foreach ($task in $oldTasks) {
      Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Confirm:$false
      Write-Output "♻️ Suppression de la tâche '$($task.TaskName)' sur compte '$($task.Principal.UserId)'"
    }
    Start-Sleep -Seconds 2
  }
} catch {
  Write-Output "⚠️ Erreur lors de la suppression : $_"
}

# --- TRIGGER AT LOGON ---
$triggers = @()
$triggers += New-ScheduledTaskTrigger -AtLogOn

# --- TRIGGERS DYNAMIQUES ---
$horaires = Get-Content $triggersFile | Where-Object { $_ -match "^\d{2}:\d{2}$" }  # format HH:mm
foreach ($h in $horaires) {
  $triggers += New-ScheduledTaskTrigger -Daily -At $h
}

# --- ACTION AVEC PWSH ---
$pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwshPath) {
  $pwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"
}

$action = New-ScheduledTaskAction -Execute $pwshPath -Argument "-ExecutionPolicy Bypass -File `"$mainScript`""

# --- PRINCIPAL UTILISATEUR COURANT (MODE NORMAL) ---
$userId = "$env:USERDOMAIN\$env:USERNAME"
# Utilisation de RunLevel Limited pour éviter les problèmes d'accès aux fichiers utilisateur
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited

# --- PARAMÈTRES DE LA TÂCHE ---
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd

# --- CREATION DE LA TACHE ---
try {
  Register-ScheduledTask -TaskName $taskName -Trigger $triggers -Action $action -Principal $principal -Settings $settings
  Write-Output "✅ Nouvelle tâche planifiée '$taskName' créée avec succès pour l'utilisateur '$userId'."
  Write-Output "📌 Triggers : AtLogOn, $($horaires -join ', ')"
  Write-Output "🔧 Utilise : $pwshPath"
  Write-Output "🛡️ Mode d'exécution : Utilisateur normal (pas d'élévation)"
} catch {
  Write-Output "❌ Erreur lors de la création : $_"
}

# --- VERIFICATION ---
$createdTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($createdTask) {
  Write-Output " "
  Write-Output "✅ Tâche vérifiée :"
  $createdTask.Actions | ForEach-Object {
    Write-Output "   Execute: $($_.Execute)"
    Write-Output "   Arguments: $($_.Arguments)"
  }
} else {
  Write-Output "❌ La tâche n'a pas été créée correctement"
}
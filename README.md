# 🛠 AutoCopy New+ (PowerToys Nouveau+)

## 📌 Présentation

**AutoCopy New+** synchronise automatiquement vos fichiers et dossiers de référence depuis le serveur d'entreprise vers le dossier de modèles **PowerToys Nouveau+**.

### ✨ Fonctionnalités principales :

- Copier **fichiers individuels** ou **dossiers complets**
- Ignorer certaines extensions indésirables (`.bak`, `.tmp`, etc.)
- Planification automatique à la connexion et aux heures choisies
- Journalisation complète des actions

---

## 🗂️ Organisation des fichiers

```
autocopy new+
│── update-models.ps1      # Script principal de copie
│── install-schedule.ps1   # Création de la tâche planifiée
│── files.txt              # Liste des fichiers/dossiers à copier (à créer)
│── banlist.txt            # Extensions à ignorer
│── triggers.txt           # Horaires de déclenchement
│── files.example.txt      # Exemple de configuration
│── update-models.log      # Journal des actions (généré automatiquement)
└── README.md              # Documentation
```

---

## ⚙️ Configuration

### 1️⃣ files.txt

- 1 chemin absolu par ligne (UNC ou local)
- Syntaxe :
  - Fichier unique :
    ```
    \\MONSERVEUR\partage\modele1.docx
    ```
  - Dossier complet :
    ```
    \\MONSERVEUR\partage\DossierModeles
    ```
  - Contenu du dossier uniquement :
    ```
    \\MONSERVEUR\partage\DossierModeles\*
    ```
- Les guillemets sont supprimés automatiquement, donc copier depuis l'explorateur fonctionne directement.

### 2️⃣ banlist.txt

- Extensions à **ignorer** (minuscules, sans `*`)

Exemple :

```
.bak
.tmp
.log
```

### 3️⃣ triggers.txt

- Horaires de déclenchement quotidien au format `HH:MM`
- Un horaire par ligne

Exemple :

```
08:30
12:30
```

**Note :** Penser à relancer `install-schedule.ps1` pour appliquer les changements.

---

## 🚀 Installation

1. Configurez `update-models.ps1`, `files.txt` et `banlist.txt`.
2. **Installez la tâche planifiée** :
   - **Option A** : Double-cliquez sur `install-schedule.ps1`
   - **Option B** : Exécutez en PowerShell :
     ```powershell
     pwsh.exe -ExecutionPolicy Bypass -File "<CHEMIN_VERS_LE_DOSSIER>\install-schedule.ps1"
     ```
   - Le script se relance automatiquement en **mode administrateur** si nécessaire.
   - Supprime toute ancienne tâche `UpdatePowerToysModels`.
   - Crée une nouvelle tâche planifiée pour :
     - 🖱 Exécution à chaque connexion utilisateur
     - ⏰ Exécution quotidienne à 17h00
3. La tâche est visible dans **Planificateur de tâches → Bibliothèque du Plaificateur de tâches** et s'exécute en mode utilisateur normal.

---

## 🧑‍💻 Commandes utiles

### ✅ Vérifier la tâche

```powershell
Get-ScheduledTask -TaskName "UpdatePowerToysModels"
```

### 📅 Voir les prochains déclenchements

```powershell
Get-ScheduledTaskInfo -TaskName "UpdatePowerToysModels"
```

### ▶️ Lancer la tâche manuellement

```powershell
Start-ScheduledTask -TaskName "UpdatePowerToysModels"
```

### 🗑️ Supprimer la tâche

```powershell
Unregister-ScheduledTask -TaskName "UpdatePowerToysModels" -Confirm:$false
```

---

## 📄 Logs

Fichier : `update-models.log`

Exemple :

```
[2025-09-12 12:30:01] 🔄 Début de la mise à jour des modèles PowerToys...
[2025-09-12 12:30:01] ✅ Copié : template1.docx
[2025-09-12 12:30:01] ⏭️ Ignoré (extension bannie) : plan.bak
[2025-09-12 12:30:01] 🎉 Mise à jour terminée.
```

---

## 🔧 Personnalisation

- **Ajouter/supprimer des fichiers** → modifier `files.txt`
- **Modifier les extensions à ignorer** → éditer `banlist.txt`
- **Changer les horaires** → modifier les triggers dans `install-schedule.ps1`
- **Exécuter immédiatement** → `Start-ScheduledTask -TaskName "UpdatePowerToysModels"`

---

## ⚠️ Conseils

- Toujours exécuter `install-schedule.ps1` en mode administrateur au premier lancement.
- Vérifier que le dossier PowerToys Nouveau+ existe :
  ```
  %LOCALAPPDATA%\Microsoft\PowerToys\NewPlus\Modèles
  ```
- Les fichiers sur le serveur doivent être accessibles depuis le poste utilisateur.

---

## ✅ Résultat attendu

- Dossier de modèles toujours à jour
- Logs détaillés pour suivi
- Tâche planifiée fiable et visible dans le Planificateur

Conçu pour simplifier la mise à jour des modèles PowerToys Nouveau+ et éviter les fichiers indésirables.

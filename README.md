# HtmlToXml - Extracteur de contenu textuel de sites web

## Description
Ce script PowerShell permet d'extraire le contenu textuel visible des pages principales d'un site web et de le stocker dans un fichier XML structuré.

## Utilisation

```powershell
.\digest.ps1 -url "https://www.apple.com/fr"
```

## Fonctionnement
Le script analyse automatiquement la page d'accueil pour identifier les liens du menu principal, puis visite chaque page pour extraire son contenu textuel. Il génère un fichier XML contenant toutes les données collectées.

## Exemple de résultat
Avec l'URL `https://www.apple.com/fr`, le script produit un fichier XML nommé d'après le titre du site (ex: `Apple__France__20250525_141516.xml`). Ce fichier contient une structure XML avec :
- L'URL de chaque page visitée
- Le contenu textuel extrait (sans balises HTML)
- Les informations des pages du menu principal comme l'App Store, l'assistance Apple, iCloud, etc.

## Format de sortie
Le fichier XML généré suit une structure simple avec des éléments `<page>` contenant chacun une `<url>` et le `<text>` correspondant, permettant une analyse facile du contenu textuel du site.

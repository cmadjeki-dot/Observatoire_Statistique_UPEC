# Consulter le site et les tableaux de bord

Projet personnel indépendant de l’UPEC. Données synthétiques, résultats non officiels.

| Outil | Accès | Fonctionnement |
|---|---|---|
| Site public | https://cmadjeki-dot.github.io/Observatoire_Statistique_UPEC/ | Cinq vues interactives, filtres, export CSV et rapport final |
| Shiny | http://127.0.0.1:3838 | Application R sur le poste où son serveur est lancé |
| Power BI Desktop | `powerbi/Observatoire.pbip` | Rapport natif local, après actualisation des exports |

Les vues du site restituent les 33 lignes d’indicateurs contrôlés, avec année,
diplôme pour l’insertion, numérateur, dénominateur, couverture et statut.
Elles ne sont ni une session Shiny embarquée ni un rapport Power BI Service.
GitHub Pages héberge des fichiers statiques et JavaScript ; il n’exécute pas R.

## Shiny et Power BI sur votre poste

Depuis une session R activant renv à la racine :

```r
source("scripts/run_shiny.R")
```

Ouvrir `http://127.0.0.1:3838`. Le serveur doit rester actif ; Ctrl+C l’arrête.
Pour Power BI, sur un nouveau poste :

```r
source("scripts/refresh_dashboards.R")
source("scripts/build_powerbi.R")
```

Ouvrir ensuite `powerbi/Observatoire.pbip` dans Desktop et cliquer sur Actualiser.
Le générateur réécrit les définitions : préserver les personnalisations avant
relance. Pour une actualisation ordinaire, seul le script de données est requis.
Un hébergement Shiny ou Power BI Service distant nécessite une configuration
de compte et de publication distincte, qui n’est pas réalisée ici.

## Construire et publier le site

Les sources sont dans `site/`. Le générateur vérifie le pipeline et les exports,
rend le rapport final puis copie uniquement les fichiers publics :

```r
source("scripts/build_project_site.R")
```

Les fichiers générés sont dans `outputs/site_github/`, ignoré sur `main`.
La branche de publication est `gh-pages`. Sur un nouveau poste, si ce dossier
n’existe pas, récupérer cette branche **avant** de lancer la construction :

```powershell
git clone --branch gh-pages --single-branch https://github.com/cmadjeki-dot/Observatoire_Statistique_UPEC.git outputs/site_github
```

Après construction et recette, publier explicitement les fichiers générés :

```powershell
git -C outputs/site_github add -- index.html style.css app.js data.json rapport_final.html .nojekyll
git -C outputs/site_github commit -m "Actualise le site et les indicateurs controles"
git -C outputs/site_github push origin gh-pages
```

L’actualisation reste déclenchée manuellement. Les données individuelles,
archives de travail, caches et paramètres locaux ne sont pas déployés sur le site.
Le rapport et les agrégats synthétiques sont publiés volontairement sur cette
branche, distinctement des exclusions de résultats sur `main`.

## Recette navigateur

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check_project_site.ps1 -Url https://cmadjeki-dot.github.io/Observatoire_Statistique_UPEC/
```

Cette recette utilise Edge sans fenêtre : cinq vues, filtre licence à trois
lignes, deux censures de Parcours en dernière année, affichage mobile sans
débordement horizontal. Les captures et résultats sont dans `outputs/site_validation/`.
Le navigateur de recette est fermé à la fin ; le navigateur utilisateur reste ouvert.

# Préparation de la publication GitHub — étape 32

Audit local du 19 octobre 2026. Démonstrateur personnel indépendant de l’UPEC,
données synthétiques et résultats non officiels.

## État constaté

- Branche : `main`.
- Un commit initial : `8b25245`.
- Aucun remote configuré ; aucun dépôt distant créé pendant cette étape.
- GitHub CLI disponible. L’authentification distante n’a pas été vérifiée.
- Les développements récents sont encore modifiés ou non suivis.

L’inventaire local est dans `outputs/publication/inventaire.csv`. Avant ajout du
présent document, il contenait 171 fichiers candidats, représentant 1 048 227 octets.
Il décrit les fichiers suivis et non suivis non ignorés, pas le contenu de
tous les dossiers locaux exclus.

## Fichiers proposés à la publication

| Ensemble | Contenu proposé |
|---|---|
| Environnement | `.Rprofile`, `.Rbuildignore`, `.Renviron.example`, `.gitignore`, `DESCRIPTION`, `renv.lock`, `renv/activate.R`, `renv/settings.json`, `renv/.gitignore` |
| VS Code | `.vscode/` ; chemins des exécutables à adapter sur un autre poste |
| Calculs | `R/`, `config/indicators.yml`, `config/simulation.R`, `_targets.R` |
| Exécution et contrôle | `scripts/`, `tests/` |
| Restitution | `README.md`, `docs/`, sources `notebooks/` et `reports/`, `dashboard/` |
| Power BI | `powerbi/`, sauf paramètre local et caches ignorés |
| Structure et publication des données | Fichiers `.gitkeep` existants et `data/public/synthetic/README.md` |

Les répertoires `app/` et les fichiers de structure déjà suivis peuvent rester
pour préserver l’historique. Aucun CSV de données n’est actuellement sélectionné
dans `data/public/synthetic/`.

## Exclusions contrôlées

Les archives brutes et préparées, `outputs/`, les magasins `targets`, les
bibliothèques et caches `renv`, les `.pbix`, `.pbi`, secrets et configurations
locales restent exclus. Le paramètre Power BI `expressions.tmdl` est local et
doit être reconstruit sur un autre poste selon le README.

`git check-ignore` a confirmé les exclusions sur les chemins de contrôle des
données, rendus, caches, paramètre Power BI, `.Renviron` et `.env`.
Aucun artefact RDS/PBIX/clé privée n’a été repéré parmi les candidats.

La recherche de signatures de jetons GitHub, clés AWS, clés privées et clés de
type API n’a identifié aucun candidat sensible, ni dans les fichiers candidats
ni dans le commit initial. C’est une recherche par signatures, pas une garantie
d’absence de tout secret. Les dossiers ignorés ne sont pas proposés au push.
Les chemins locaux détectés dans certains scripts ou documents sont des
configurations d’exécutables ou des exemples à adapter, pas des identifiants.

## Découpage proposé des commits

1. **Ajouter la chaîne statistique synthétique et ses tests** : modules de
   données, qualité, analyses, modèles, enquêtes, configuration, tests et notebooks.
2. **Automatiser les calculs et livrer les tableaux de bord** : pipeline,
   lanceurs, Shiny, Power BI, dépendances, tâches et règles d’exclusion.
3. **Documenter la reproduction et les restitutions finales** : README,
   documents de cadrage, guides, rapports et présentation orale.

Avant chaque commit : contrôler la liste explicite des fichiers, le diff indexé,
les exclusions et la cohérence des dépendances. Éviter `git add .` sans examen.
La vérification finale des étapes 36–37 pourra justifier des corrections avant
le dernier commit et la publication.

## Confirmation nécessaire avant mutation Git et publication

Confirmer la destination exacte `proprietaire/nom-du-depot` ou son URL GitHub,
la visibilité publique ou privée, et l’accord sur les ensembles de fichiers
ci-dessus. Aucune licence de réutilisation n’est choisie implicitement ; si une
licence doit être ajoutée, elle doit être sélectionnée explicitement.

Après confirmation seulement : préparer les commits, configurer la destination,
vérifier son état distant et effectuer le push. Aucun ajout à l’index, commit,
création distante ou push n’a été exécuté pendant cet audit.

## Destination indiquée et vérifiée

L’utilisateur a indiqué `https://github.com/cmadjeki-dot/Observatoire_Statistique_UPEC`.
La lecture GitHub confirme un dépôt **public**, une branche `main` et un dernier
commit `1b9f0b70634addc6a143ab902810377628a7f4c7`. L’arbre distant contient
uniquement `README.md`, dont la présentation du besoin métier est déjà couverte
par le README local détaillé.

Le plan proposé est de conserver l’historique distant, y intégrer les sources
auditées, puis publier sans push forcé. Les règles `.gitattributes` complètent
les fichiers d’environnement à publier. L’inventaire actualisé, avec tailles et
empreintes, est dans `outputs/publication/fichiers_proposes.csv` (non publié).
La confirmation du périmètre et de sa publication publique reste attendue avant
les commits et le push ; aucun remote local n’a encore été configuré.

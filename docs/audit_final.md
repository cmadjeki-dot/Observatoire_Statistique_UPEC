# Audit du projet sur 100 — étape 36

Date : 19 octobre 2026. Évaluation technique interne du démonstrateur personnel
indépendant de l’UPEC. Données entièrement synthétiques ; aucun résultat officiel.

Mise à jour après cet audit : la [validation technique de l’étape 37](validation_technique_finale.md)
a réussi localement et le statut du cahier des charges a été clarifié.
Le présent texte conserve le constat et la note de l’étape 36 ; les conditions
techniques levées sont détaillées dans le bilan de clôture. Les réserves métier,
de validation indépendante et de publication restent distinctes.

## Verdict : 84 / 100 — démonstrateur abouti, clôture technique conditionnelle

Le projet couvre la chaîne de génération, qualité, préparation, analyse et
restitution, avec deux interfaces réellement exercées. Les définitions limitent
les confusions usuelles entre réussite et diplôme, sortie et abandon, réponse
et représentativité. La note porte sur ce périmètre démonstrateur ; elle ne vaut
ni certification, ni validation par l’UPEC, ni autorisation d’usage réel.

La clôture technique reste conditionnée à la validation transversale de l’étape 37.
La publication GitHub reste distinctement suspendue à la confirmation de sa
destination et de ses fichiers. L’exploitation institutionnelle demanderait un
cadrage et une validation supplémentaires.

## Barème argumenté

| Domaine | Note | Éléments probants | Réserve justifiant les points non attribués |
|---|---:|---|---|
| Cadrage | 9 / 10 | Cahier des charges, protocole, dictionnaires, questions métier et exclusions explicites | Des documents initiaux gardent un statut de proposition qui mérite d’être contextualisé ; validation par de vrais utilisateurs absente |
| Architecture | 9 / 10 | Fonctions dans `R/`, séparation données/notebooks/outputs, lanceurs et magasins isolés | Quelques dossiers hérités vides et documents historiques complexifient la navigation |
| Données | 9 / 10 | 15 000 personnes, 31 816 inscriptions, onze tables, identifiants stables et anomalies distinctes | Mécanismes pédagogiques simplifiés ; absence de validation externe du réalisme des distributions |
| Qualité | 9 / 10 | Contrôles relationnels et temporels, journal, comparaison avant/après, empreintes | Le nettoyage bénéficie de la vérité simulée ; couverture de toutes les anomalies réelles non démontrée |
| Statistiques | 13 / 15 | Dénominateurs, couverture, horizons et censure documentés ; enquêtes et devenir distingués | Analyses principalement descriptives ; approfondissement des sensibilités et de la sélection réservé à un usage ultérieur |
| Modélisation | 12 / 15 | Choix préalable, GLM, références, test séparé, diagnostics, calibration et référence constante | Cas complets, influence et stabilité à approfondir ; validation interne seule, sans validation temporelle ou externe |
| Code R | 8 / 10 | 35 fichiers R parsés dans cet audit, fonctions réutilisables, chemins contrôlés | Pas de preuve actuelle d’analyse statique exhaustive ou de revue indépendante ; audit transversal encore à faire |
| Tests | 4 / 5 | 23 fichiers de tests ; dernière recette complète : 976 assertions sans échec ; recettes natives et navigateur | Suite complète non relancée à cette étape ; couverture du code non quantifiée et absence d’intégration continue publiée |
| Reproductibilité | 3 / 5 | `renv`, `targets`, manifestes, modes de reconstruction et lanceurs documentés | Restauration sur un autre poste non démontrée ; développements récents non tous commités, aucun remote |
| Restitution | 4 / 5 | Rapport final, note, huit constats, Shiny et Power BI, concordance DAX/R | Agrégats globaux sans filtre formation ; validation d’accessibilité et d’utilité auprès de vrais responsables non réalisée |
| Présentation | 4 / 5 | Diaporama, conducteur en dix parties, discours et 30 questions de jury rendus | Aucun oral chronométré ni entraînement observé devant un jury |
| **Total** | **84 / 100** | **Barème total : 100 points** | **Note non assimilable à un pourcentage d’avancement** |

Une AUC faible ne justifie pas à elle seule une pénalité : la transparence sur
la portée du modèle est un point positif. La réserve concerne la profondeur de
sa validation. De même, l’absence d’effet causal ou de score psychométrique
forcé est méthodologiquement justifiée, et ne constitue pas une lacune à corriger.

## Preuves consultées et contrôles exécutés

| Contrôle | État à l’étape 36 | Preuve |
|---|---|---|
| Syntaxe des modules, scripts R et `_targets.R` | 35 fichiers parsés sans erreur | Inventaire de cette étape dans `outputs/audit_final/inventaire_sources.csv` |
| Produits et sources de calcul | Lecteur contrôlé exécuté, intégrité conforme | `outputs/pipeline_rapport/produits.csv`, `sources.csv`, `statut.csv` |
| Qualité après traitement | 209 règles, zéro alerte dans le résultat chargé | `resultats.rds`, composante `qualite` |
| Modèle chargé | Convergence vraie en quatre itérations ; 8 316 observations d’apprentissage, 14 paramètres | `resultats.rds`, composante `diagnostics` |
| Test du modèle enregistré | 2 081 observations ; AUC 0,5927, Brier 0,2164 ; référence Brier 0,2218 | `resultats.rds`, composante `evaluation` |
| Rapports et supports oraux | Fichiers présents ; quatre manifestes récents contrôlés | Rapport final, conducteur 13, discours et jury dans `outputs/` |
| Suite de tests complète | Preuve antérieure : 976 assertions réussies ; pas de nouvelle exécution ici | `outputs/pipeline_dashboard/recette_tableaux.md` |
| Shiny et Power BI | Recettes antérieures documentées, non rejouées ici | `outputs/shiny_validation/`, `outputs/powerbi_validation/` |
| Dépendances | `renv::status()` contrôlé pendant cet audit | Bibliothèque et lockfile synchronisés |
| Git | Branche `main`, aucun remote, modifications non commités ; diff sans erreur de blancs | `git status`, `git remote -v`, `git diff --check` ; avis LF/CRLF uniquement |

Les diagnostics signalent 645 leviers et 288 distances de Cook au-delà des
seuils implémentés, sans suppression automatique. Ces signalements demandent
une lecture contextualisée : ils ne prouvent pas à eux seuls une invalidité
du modèle ni des données. Les performances ne justifient aucun ciblage individuel.

Les preuves de tests et d’interfaces sont distinguées des contrôles exécutés
aujourd’hui dans cet audit. Un fichier de preuve ancien ne constitue pas une
nouvelle recette. L’inventaire MD5 constate l’état des entrées examinées ; il ne
remplace pas un lancement de la chaîne complète.

## Corrections et actions indispensables avant clôture

1. **Exécuter l’étape 37 sur l’état final.** Relancer les tests, le contrôle du
   code, le pipeline via son lanceur `targets`, les rendus Quarto, le contrôle
   renv et le démarrage Shiny. Enregistrer erreurs, avertissements et décisions.
   Un échec ne doit pas être masqué par la présence d’anciens fichiers.
2. **Clarifier le statut des documents initiaux.** Indiquer que le cahier des
   charges initial est un cadrage historique et distinguer validation interne
   du démonstrateur et absence de validation institutionnelle. Conserver
   l’historique sans inventer une approbation externe.
3. **Figer une version source identifiable avant publication.** Après confirmation
   explicite de destination et de périmètre : contrôler le diff indexé et créer
   les commits. La publication n’est pas autorisée par le seul audit.

Ces actions ne révèlent pas d’erreur numérique avérée dans les produits examinés.
Elles constituent des conditions de clôture ou de publication, et non une demande
d’installer des outils ou de remplacer les données.

## Améliorations recommandées, hors conditions de clôture du démonstrateur

- Répéter le discours à voix haute et mesurer la durée ; observer une séance de jury.
- Réaliser une reproduction sur un autre poste puis envisager une intégration continue.
- Approfondir stabilité du modèle, sélection des cas complets et analyses de sensibilité.
- Recueillir les retours d’utilisateurs sur vocabulaire, lisibilité, filtres et accessibilité.
- Ajouter des agrégats par formation si le besoin métier le justifie, sans inventer
  de ventilation à partir des seuls exports globaux.
- Produire le PDF seulement si un environnement LaTeX est volontairement disponible.

Le seuil de diffusion de dix observations est une convention du démonstrateur,
pas une garantie universelle de confidentialité. Toute utilisation de données
réelles exigerait un cadrage spécifique avec les acteurs habilités. Un déploiement
et une actualisation planifiée restent hors de la validation locale actuelle.

## Décision proposée

**Accepter le projet comme démonstrateur statistique documenté et présentable,
sous réserve de la validation technique finale.** Ne pas annoncer une publication
GitHub, un PDF, un service en production ou une validation UPEC tant que ces
opérations ne sont pas réalisées et prouvées. La note pourra être révisée après
l’étape 37 si des faits nouveaux justifient une modification argumentée.

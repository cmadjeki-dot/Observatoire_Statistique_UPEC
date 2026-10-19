# Plan de simulation — version 0.1

Les décisions D01 à D07 ont été acceptées au passage à cette étape, le
18 octobre 2026. Les paramètres et questionnaires ont été acceptés à la demande
de génération de la phase B. Le générateur est exécuté en mémoire à l'étape 12,
testé à l'étape 13 et exécuté avec sauvegarde brute dans le notebook 01 à
l'étape 14. Projet personnel indépendant de l'UPEC.

## Volumes et formations

`config/simulation.R` est la source des valeurs numériques, lisible par
`dget(here::here("config", "simulation.R"))`. Sa lecture n'effectue aucun tirage
et ne crée aucun fichier ; son statut est `valide`.

Les 15 000 personnes comprennent 11 000 premières observations en 2023-2024,
puis 2 000 nouveaux L1 chaque année suivante. Répartition initiale : 4 000 L1,
2 500 L2, 2 000 L3, 1 500 M1, 1 000 M2. Les niveaux avancés ne sont pas des
entrants L1. Les effectifs annuels ultérieurs dépendront des sorties.

Trois licences et deux masters abstraits sont proposés. Les poids d'affectation
s'appliquent dans le cycle. Une réorientation reste au même niveau, vers une
autre formation du même cycle : retirer la formation d'origine et renormaliser
les poids. Une poursuite L3 → M1 peut rejoindre les deux masters. Aucun retour
après sortie n'est simulé dans cette version, même si le protocole permet de
qualifier un tel retour dans une extension.

## Ordre des traitements du générateur

1. Utiliser le générateur et les six graines distinctes déclarés, avec tri stable
   des identifiants. Préserver et restaurer l'état aléatoire de la session appelante.
2. Créer étudiants et formations, avec bac, parcours et effet individuel latent
   normal fixe sur le suivi. Ce dernier n'est pas une variable observable réelle.
3. Générer les inscriptions et la bourse annuelle. Conserver le statut précédent
   avec la probabilité configurée ; sinon retirer le statut selon la référence.
4. Générer résultats puis inscriptions suivantes selon les distributions
   conditionnelles. Dériver les parcours, sans les tirer indépendamment.
5. Enregistrer décisions de diplôme et attributions, puis invitations éligibles.
6. Générer les deux enquêtes dans leurs fenêtres. L'évaluation de juin ne dépend
   pas d'une décision annuelle prise en septembre suivant.
7. Contrôler et sauvegarder la base cohérente. Injecter les anomalies uniquement
   dans une copie distincte, avec journal. Calculs et exports Power BI viendront ensuite.

## Réussite et parcours

La probabilité de validation proposée est
`plogis(qlogis(p_reference) + effet_bac + effet_reprise + effet_individuel)`.
Les valeurs configurées sont artificielles, sans estimation ni affirmation sur
l'UPEC. Les probabilités marginales obtenues différeront des références.

Le bac sera masqué après génération des relations ; sa valeur latente ne sera
pas fournie aux analyses comme si elle était observée. Les motifs de bac et
bourse manquants seront `non_disponible`. La bourse n'a pas d'effet direct imposé
sur la réussite ; elle intervient dans la réponse à l'enquête pour illustrer une
non-réponse différenciée. Aucune conclusion réelle n'en découlera.

Après tirage de la décision annuelle, certains résultats deviennent inconnus,
avec motif `non_disponible` ; moyenne, ECTS et date de décision deviennent `NA`.
Sinon, tirer la moyenne uniformément dans l'intervalle configuré selon la
validation. Affecter 60 ECTS si validé, ou tirer uniformément parmi les valeurs
configurées si non validé. Ce modèle simplifié ne reproduit ni compensation
complexe ni règlement pédagogique réel.

En décision inconnue, le maintien dans la même formation au même niveau donne
une transition « autre », pas un redoublement certain. Le master validé conduit
à une sortie du champ, jamais qualifiée automatiquement de décrochage.

Les étudiants initialement dans un niveau avancé possèdent des prérequis
synthétiques validés, notamment en L3/M2.
Pour les autres, les prérequis dérivent des acquis précédents ; une réorientation
au même niveau les conserve selon cette convention simplifiée. Attribuer le
diplôme si validation terminale et prérequis réunis ; décision non si refus
définitif ou prérequis insuffisants ; inconnu si résultat terminal inconnu.
Date proposée : 30 septembre de l'année de fin. Les diplômes de septembre 2026
ne sont pas matures à six mois au gel : aucune invitation ni non-réponse imputée.

## Enquêtes

Évaluation : probabilité de participation obtenue par une relation logistique
sur la bourse sous-jacente. Pour chaque item : tirer « non concerné » ; sinon
tirer la non-réponse à l'item ; sinon une modalité de satisfaction. Si les trois
items sont manquants par non-réponse, ne pas conserver de ligne de réponse et
classer l'invitation `aucune`. « Non concerné » est un item renseigné, mais ne
contribue pas à la satisfaction. Les items sont indépendants dans cette version :
aucun score latent ni argument psychométrique ne sera déduit de cette construction.

Devenir : tirer la participation au module séparément de la situation, puis
masquer éventuellement la situation des répondants avec motif `non_reponse_item`.
La distribution des situations dépend du diplôme. Les études ont priorité dans
la catégorie principale. L'emploi pendant les études est une question séparée.
L'éligibilité est établie avant tirage, à partir des fenêtres closes au gel.

## Anomalies et vérification

Prévoir dix injections par type configuré. Définir champs et lignes exacts avant
injection ; ne pas altérer deux fois la même observation ; journaliser la valeur
initiale, la nouvelle valeur et les contrôles attendus. Une injection peut
déclencher plusieurs alertes : leur nombre n'est pas celui des injections.

Les mécanismes sont implémentés dans `R/data/simulate_data.R`. Le script
`scripts/check_simulation.R` réalise une génération complète et ses vérifications
d'intégration, sans sauvegarder les tables. Les tests unitaires sont dans
`tests/testthat/`. Le notebook `01_generation_des_donnees.qmd` sauvegarde les
objets sans nettoyage via `R/data/raw_storage.R`, avec manifeste MD5 et refus
d'écrasement d'un contenu différent. Le rapport qualité reste prévu à l'étape 16.

La graine diplômes est réservée à ce domaine ; l'attribution est déterministe
dans cette version, sans tirage supplémentaire. Modifier les paramètres change
les données attendues et nécessite de relancer tous les contrôles.
